jsx
import React, { useEffect, useState } from 'react';
import { fetchStudentProfile } from '../services/api';
import { useParams } from 'react-router-dom';

export default function StudentProfile() {
  const { id } = useParams();
  const [data, setData] = useState(null);

  useEffect(() => { fetchStudentProfile(id).then(setData); }, [id]);

  if (!data) return <div className="p-6">Loading...</div>;

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Profile: {data.student?.name}</h1>
      <section className="mb-4">
        <h2 className="font-semibold">Surveys</h2>
        <ul>{data.surveys.map(s => <li key={s.survey_id}>{s.date} — stress: {s.stress_level}, sleep: {s.sleep_hours}</li>)}</ul>
      </section>
      <section>
        <h2 className="font-semibold">Service Usage</h2>
        <ul>{data.usage.map(u => <li key={u.usage_id}>{u.date} — {u.service_name} ({u.duration_min} min)</li>)}</ul>
      </section>
    </div>
  );
}



