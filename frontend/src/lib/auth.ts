export function parseJwt(token: string): { sub: string; email: string } | null {
  try {
    const base64 = token.split('.')[1];
    const payload = JSON.parse(atob(base64));
    return { sub: payload.sub, email: payload.email };
  } catch (e) {
    console.error('Invalid token', e);
    return null;
  }
}
