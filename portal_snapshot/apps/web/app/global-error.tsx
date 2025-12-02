"use client";

import FallbackError from "~/components/FallbackError";

export default function GlobalError({ error }: { error: Error }) {
  return <FallbackError />;
}
