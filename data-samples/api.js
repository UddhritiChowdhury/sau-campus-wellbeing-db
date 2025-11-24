js
import axios from 'axios';
const API = axios.create({ baseURL: process.env.REACT_APP_API_URL || 'http://localhost:4000/api' });

export const fetchStudents = () => API.get('/students').then(r => r.data);
export const fetchStudentProfile = (id) => API.get(`/students/${id}/profile`).then(r => r.data);
export const fetchServices = () => API.get('/services').then(r => r.data);
export const fetchServiceSummary = () => API.get('/services/usage/summary').then(r => r.data);
export const fetchEnvironment = () => API.get('/environment/locations').then(r => r.data);

