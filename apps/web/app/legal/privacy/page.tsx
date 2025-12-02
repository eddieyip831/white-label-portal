import PublicHeader from '~/components/public/PublicHeader';

export default function PrivacyPolicyPage() {
  return (
    <>
      <PublicHeader />

      <main className="mx-auto max-w-3xl px-6 py-12">
        <h1 className="mb-6 text-3xl font-bold">Privacy Policy</h1>

        <p className="mb-4 leading-7 text-gray-700">
          This is a placeholder Privacy Policy page for the Portal Framework.
          Replace this placeholder content with your real privacy policy
          describing how user data is collected, stored, and used.
        </p>

        <p className="mb-4 leading-7 text-gray-700">
          This page is referenced during user registration and should clearly
          outline how personal information such as email, account data, and
          profile attributes will be processed.
        </p>

        <p className="leading-7 text-gray-700">
          When you are ready, update this page with your full privacy policy or
          consider rendering it from a CMS for easier maintenance.
        </p>
      </main>
    </>
  );
}
