import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from '@kit/ui/breadcrumb';

type SuperAdminPageHeaderProps = {
  title: string;
  description?: string;
  breadcrumbLabel?: string;
};

export default function SuperAdminPageHeader({
  title,
  description,
  breadcrumbLabel,
}: SuperAdminPageHeaderProps) {
  const pageLabel = breadcrumbLabel ?? title;

  return (
    <div className="space-y-2">
      <h1 className="text-2xl font-semibold">Super Admin · {title}</h1>
      <Breadcrumb>
        <BreadcrumbList>
          <BreadcrumbItem>
            <BreadcrumbLink href="/admin/super-admin">
              Super Admin
            </BreadcrumbLink>
          </BreadcrumbItem>
          <BreadcrumbSeparator />
          <BreadcrumbItem>
            <BreadcrumbPage>{pageLabel}</BreadcrumbPage>
          </BreadcrumbItem>
        </BreadcrumbList>
      </Breadcrumb>
      {description && (
        <p className="text-sm text-gray-600">{description}</p>
      )}
    </div>
  );
}
