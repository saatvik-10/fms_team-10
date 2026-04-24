import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

type UploadScope =
  | { role: 'driver'; userId: string }
  | { role: 'maintenance'; userId: string; vehicleId: string }
  | { role: 'manager'; userId: string; documentType: 'dl' | 'rc' };

export class R2Service {
  private client: S3Client;
  private bucketName: string;
  private accountId: string;

  constructor() {
    this.accountId = process.env.CLOUDFLARE_ACCOUNT_ID || '';
    const accessKeyId = process.env.CLOUDFLARE_ACCESS_KEY_ID || '';
    const secretAccessKey = process.env.CLOUDFLARE_SECRET_ACCESS_KEY || '';
    this.bucketName = process.env.CLOUDFLARE_BUCKET_NAME || '';

    if (
      !this.accountId ||
      !accessKeyId ||
      !secretAccessKey ||
      !this.bucketName
    ) {
      throw new Error(
        `Missing R2 environment variables. Check:\n` +
          `  CLOUDFLARE_ACCOUNT_ID: ${this.accountId ? '✓' : '✗ MISSING'}\n` +
          `  CLOUDFLARE_ACCESS_KEY_ID: ${accessKeyId ? '✓' : '✗ MISSING'}\n` +
          `  CLOUDFLARE_SECRET_ACCESS_KEY: ${secretAccessKey ? '✓' : '✗ MISSING'}\n` +
          `  CLOUDFLARE_BUCKET_NAME: ${this.bucketName ? '✓' : '✗ MISSING'}`,
      );
    }

    console.log(`[R2] Initialized with:
  Account ID : ${this.accountId.slice(0, 6)}...
  Bucket     : ${this.bucketName}
  Endpoint   : https://${this.accountId}.r2.cloudflarestorage.com`);

    this.client = new S3Client({
      region: 'auto',
      endpoint: `https://${this.accountId}.r2.cloudflarestorage.com`,
      credentials: {
        accessKeyId,
        secretAccessKey,
      },
      forcePathStyle: true,
    });
  }

  private sanitizeFileName(fileName: string) {
    // Keep only safe filename characters to avoid path traversal and odd keys.
    return fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
  }

  private buildKey(params: { folderPath: string; fileName: string }) {
    const safeName = this.sanitizeFileName(params.fileName);
    return `${params.folderPath}/${Date.now()}_${safeName}`;
  }

  private uploadToFolder(params: {
    folderPath: string;
    fileName: string;
    body: Buffer | Uint8Array | string;
    contentType?: string;
  }) {
    const key = this.buildKey({
      folderPath: params.folderPath,
      fileName: params.fileName,
    });

    return this.uploadObject({
      key,
      body: params.body,
      contentType: params.contentType,
    }).then(() => ({ key }));
  }

  private async getFolderSignedUploadUrl(params: {
    folderPath: string;
    fileName: string;
    contentType?: string;
    expiresIn?: number;
  }) {
    const key = this.buildKey({
      folderPath: params.folderPath,
      fileName: params.fileName,
    });

    const url = await this.getSignedUploadUrl({
      key,
      contentType: params.contentType,
      expiresIn: params.expiresIn,
    });

    return { key, url };
  }

  private getFolderPathFromScope(scope: UploadScope) {
    if (scope.role === 'driver') {
      return `driver/${scope.userId}/images`;
    }

    if (scope.role === 'maintenance') {
      return `maintenance/${scope.userId}/vehicle/${scope.vehicleId}`;
    }

    return `manager/${scope.userId}/${scope.documentType}`;
  }

  async uploadObject(params: {
    key: string;
    body: Buffer | Uint8Array | string;
    contentType?: string;
  }) {
    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: params.key,
      Body: params.body,
      ContentType: params.contentType,
    });

    return this.client.send(command);
  }

  async uploadByScope(params: {
    scope: UploadScope;
    fileName: string;
    body: Buffer | Uint8Array | string;
    contentType?: string;
  }) {
    const folderPath = this.getFolderPathFromScope(params.scope);
    return this.uploadToFolder({
      folderPath,
      fileName: params.fileName,
      body: params.body,
      contentType: params.contentType,
    });
  }

  async getSignedUploadUrlByScope(params: {
    scope: UploadScope;
    fileName: string;
    contentType?: string;
    expiresIn?: number;
  }) {
    const folderPath = this.getFolderPathFromScope(params.scope);
    return this.getFolderSignedUploadUrl({
      folderPath,
      fileName: params.fileName,
      contentType: params.contentType,
      expiresIn: params.expiresIn,
    });
  }

  async getSignedUploadUrl(params: {
    key: string;
    contentType?: string;
    expiresIn?: number;
  }) {
    const command = new PutObjectCommand({
      Bucket: this.bucketName,
      Key: params.key,
      ContentType: params.contentType,
    });

    return getSignedUrl(this.client, command, {
      expiresIn: params.expiresIn ?? 900,
    });
  }

  async getSignedDownloadUrl(key: string, expiresIn = 900) {
    const command = new GetObjectCommand({
      Bucket: this.bucketName,
      Key: key,
    });

    return getSignedUrl(this.client, command, { expiresIn });
  }

  async deleteObject(key: string) {
    const command = new DeleteObjectCommand({
      Bucket: this.bucketName,
      Key: key,
    });

    return this.client.send(command);
  }
}
