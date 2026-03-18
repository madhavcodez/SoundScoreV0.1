/**
 * Sanitize user-submitted plain-text fields.
 * SoundScore does not support rich text — all user content is plain text.
 * Encodes HTML special characters to prevent XSS if content is ever
 * rendered in a web context, and strips any remaining HTML tags.
 */
export const stripHtml = (text: string): string =>
  text
    .replace(/<[^>]*>/g, "")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .trim();
