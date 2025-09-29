"use client"
import { Card, CardContent, CardHeader } from '@/components/ui/Card'
import { Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts'
import { useQuery } from '@tanstack/react-query'
import { call } from '@/lib/firebase'
import { FunctionNames, type GetKpisInput, type GetKpisOutput } from '@c3/contracts'

const chartData = Array.from({ length: 14 }).map((_, i) => ({
  day: `D${i + 1}`,
  newUsers: Math.round(10 + Math.random() * 20),
  bookings: Math.round(5 + Math.random() * 15),
}))

export default function OverviewPage() {
  const { data: kpi } = useQuery({
    queryKey: ['getKpis', '30d'],
    queryFn: async () => {
      const res = await call<GetKpisInput, GetKpisOutput>(FunctionNames.getKpis)({ range: '30d' })
      return res
    },
  })
  const kpis = [
    { label: 'Total Users', value: kpi?.totalUsers?.toLocaleString() ?? '—' },
    { label: 'Premium Users', value: kpi?.premiumUsers?.toLocaleString() ?? '—' },
    { label: 'Bookings (30d)', value: kpi?.totalBookings?.toLocaleString() ?? '—' },
    { label: 'Occupancy', value: kpi?.occupancyPct != null ? `${Math.round(kpi.occupancyPct)}%` : '—' },
  ]
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {kpis.map((k) => (
          <Card key={k.label}>
            <CardHeader className="text-sm text-muted">{k.label}</CardHeader>
            <CardContent>
              <div className="text-2xl font-semibold">{k.value}</div>
            </CardContent>
          </Card>
        ))}
      </div>
      <Card>
        <CardHeader className="font-medium">Last 14 days (mocked)
          <span className="ml-2 text-xs text-muted">TODO: replace with getBookingTrend()</span>
        </CardHeader>
        <CardContent className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData} margin={{ left: 8, right: 8, top: 8, bottom: 8 }}>
              <XAxis dataKey="day" stroke="var(--muted)" tickLine={false} axisLine={false} />
              <YAxis stroke="var(--muted)" tickLine={false} axisLine={false} />
              <Tooltip contentStyle={{ background: 'var(--bg)', border: '1px solid var(--border)' }} />
              <Line type="monotone" dataKey="newUsers" stroke="var(--brand-primary)" strokeWidth={2} dot={false} />
              <Line type="monotone" dataKey="bookings" stroke="#10b981" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>
    </div>
  )
}
