/**
 * Strip HTML tags from user-submitted plain-text fields.
 * SoundScore does not support rich text — all user content is plain text.
 */
export const stripHtml = (text: string): string =>
  text.replace(/<[^>]*>/g, "").trim();
