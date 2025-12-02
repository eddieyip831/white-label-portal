import PublicHeader from '~/components/public/PublicHeader';

export default function TermsPage() {
  return (
    <>
      <PublicHeader />

      <main className="mx-auto max-w-3xl px-6 py-12">
        <h1 className="mb-6 text-3xl font-bold">Terms & Conditions</h1>

        <p className="mb-4 leading-7 text-gray-700">
          This is a placeholder Terms & Conditions page for the Portal
          Framework. Replace this text with your actual legal terms. These terms
          govern the use of your platform and should be carefully reviewed by
          legal counsel before publishing.
        </p>

        <p className="mb-4 leading-7 text-gray-700">
          The purpose of this placeholder is to allow routing and registration
          flows to reference this page, ensuring your onboarding process remains
          legally compliant.
        </p>

        <p className="leading-7 text-gray-700">
          When you are ready, you can update this file with your complete Terms
          & Conditions or load them dynamically from a CMS or database.
        </p>
      </main>
    </>
  );
}
