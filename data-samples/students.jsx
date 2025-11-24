jsx
import React, { useEffect, useState } from 'react';
import { fetchStudents } from '../services/api';
import { Link } from 'react-router-dom';

export default function Students() {
  const [students, setStudents] = useState([]);
  useEffect(() => { fetchStudents().then(setStudents); }, []);
  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-4">Students</h1>
      <table className="min-w-full bg-white">
        <thead><tr><th>ID</th><th>Name</th><th>Program</th><th>Year</th></tr></thead>
        <tbody>
          {students.map(s => (
            <tr key={s.student_id}>
              <td>{s.student_id}</td>
              <td><Link to={`/students/${s.student_id}`}>{s.name}</Link></td>
              <td>{s.program}</td>
              <td>{s.year}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

