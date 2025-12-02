export default function PublicHeader() {
  return (
    <header className="flex w-full items-center justify-between border-b bg-white px-6 py-4">
      {/* Logo Placeholder */}
      <a href="/" className="flex items-center space-x-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-full bg-gray-300 font-bold text-gray-600">
          L
        </div>
        <span className="text-lg font-semibold">Portal Framework</span>
      </a>

      {/* Right-side (optional buttons) */}
      <div className="flex items-center space-x-4">
        <a href="/" className="text-sm text-gray-600 hover:underline">
          Login
        </a>
        <a
          href="/auth/register"
          className="text-sm text-blue-600 hover:underline"
        >
          Register
        </a>
      </div>
    </header>
  );
}
