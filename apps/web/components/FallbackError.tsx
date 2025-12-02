"use client";

export default function FallbackError() {
  return (
    <div style={{ padding: 20 }}>
      <h1>Something went wrong.</h1>
      <p>This is a fallback error boundary for the portal framework.</p>
    </div>
  );
}
