jsx
import React, { useEffect, useState } from 'react';
import { fetchServiceSummary, fetchEnvironment } from '../services/api';

export default function Dashboard() {
  const [services, setServices] = useState([]);
  const [env, setEnv] = useState([]);

  useEffect(() => {
    fetchServiceSummary().then(setServices);
    fetchEnvironment().then(setEnv);
  }, []);

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Campus Wellbeing Dashboard</h1>

      <section className="mb-6">
        <h2 className="text-xl font-semibold">Service Usage Summary</h2>
        <ul>
          {services.map(s => (
            <li key={s.service_id} className="py-2">
              <strong>{s.service_name}</strong> — visits: {s.visits || 0}, avg rating: {Number(s.avg_rating || 0).toFixed(1)}
            </li>
          ))}
        </ul>
      </section>

      <section>
        <h2 className="text-xl font-semibold">Environment Snapshot</h2>
        <ul>
          {env.map(e => (
            <li key={e.env_id} className="py-2">
              <strong>{e.location}</strong> — noise: {e.noise_level}, crowd: {e.crowd_density}, lighting: {e.lighting_quality}
            </li>
          ))}
        </ul>
      </section>
    </div>
  );
}

