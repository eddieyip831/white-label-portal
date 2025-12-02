export type PasswordCheck = {
  length: boolean;
  uppercase: boolean;
  lowercase: boolean;
  number: boolean;
  symbol: boolean;
  score: number; // 0–4
};

export function validatePassword(password: string): PasswordCheck {
  const checks = {
    length: password.length >= 8,
    uppercase: /[A-Z]/.test(password),
    lowercase: /[a-z]/.test(password),
    number: /\d/.test(password),
    symbol: /[^A-Za-z0-9]/.test(password),
  };

  // Score = number of satisfied conditions
  const score =
    [
      checks.length,
      checks.uppercase,
      checks.lowercase,
      checks.number,
      checks.symbol,
    ].filter(Boolean).length - 1; // result will be 0–4

  return { ...checks, score };
}
