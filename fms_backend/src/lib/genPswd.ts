import { customAlphabet } from 'nanoid';

const generateAlphabeticPassword = customAlphabet(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ',
  10,
);

export const genPswd = () => generateAlphabeticPassword();