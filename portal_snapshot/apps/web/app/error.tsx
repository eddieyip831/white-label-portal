"use client";

import FallbackError from "~/components/FallbackError";

export default function Error({ error }: { error: Error }) {
  return <FallbackError />;
}
