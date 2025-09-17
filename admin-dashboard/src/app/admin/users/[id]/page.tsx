export default async function UserDetailsPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  return <div>User details for {id}</div>
}
