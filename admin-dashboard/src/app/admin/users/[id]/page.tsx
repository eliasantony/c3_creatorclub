type Props = { params: { id: string } }

export default function UserDetailsPage({ params }: Props) {
  return <div>User details for {params.id}</div>
}
