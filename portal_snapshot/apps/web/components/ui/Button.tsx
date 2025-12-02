"use client";

import type { ButtonHTMLAttributes } from "react";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: "primary" | "secondary";
};

export function Button({ variant = "primary", className = "", ...props }: ButtonProps) {
  const base =
    "inline-flex items-center justify-center rounded-md px-4 py-2 text-sm font-medium border";

  const styles =
    variant === "primary"
      ? "bg-black text-white border-black"
      : "bg-white text-black border-gray-300";

  return <button className={`${base} ${styles} ${className}`} {...props} />;
}
