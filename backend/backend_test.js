async function test() {
  try {
    const loginRes = await fetch('http://localhost:3000/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'admin@clinic.com', password: 'admin' })
    }).then(r => r.json());
    
    if (!loginRes.data || !loginRes.data.accessToken) {
      console.log('Login failed:', loginRes);
      return;
    }
    const token = loginRes.data.accessToken;
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };
    
    const patients = await fetch('http://localhost:3000/api/patient-profiles', { headers }).then(r => r.json());
    const patient_id = patients.data[0].id;
    
    const slotsResponse = await fetch('http://localhost:3000/api/slots/available?clinicId=1&doctor_id=1&fromDate=2026-04-01&toDate=2026-04-30', { headers }).then(r => r.json());
    if (!slotsResponse.data || !slotsResponse.data.items || slotsResponse.data.items.length === 0) {
      console.log('No slots available', slotsResponse);
      return;
    }
    const slot_id = slotsResponse.data.items[0].slot_id;
    
    const servicesResp = await fetch('http://localhost:3000/api/services?facility_id=1', { headers }).then(r => r.json());
    if (!servicesResp.data || servicesResp.data.items.length === 0) {
      console.log('No services available', servicesResp);
      return;
    }
    const service_id = servicesResp.data.items[0].id;
    
    const appt = await fetch('http://localhost:3000/api/appointments', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        patient_id: patient_id.toString(),
        facility_id: '1',
        doctor_id: '1',
        service_id: service_id.toString(),
        slot_id: slot_id.toString(),
        appointmentType: 'consultation',
        appointment_date: '2026-04-20',
        appointment_time: '08:00',
        note: 'Được tạo tự động bởi trợ lý AI để test luồng dịch vụ'
      })
    }).then(r => r.json());
    
    console.log('Appointment created:', JSON.stringify(appt));
    
    if (appt.data && appt.data.appointment_id) {
      const payment = await fetch('http://localhost:3000/api/payments', {
        method: 'POST',
        headers,
        body: JSON.stringify({
          appointment_id: appt.data.appointment_id.toString(),
          paymentMethod: 'vnpay'
        })
      }).then(r => r.json());
      console.log('Payment created:', JSON.stringify(payment));
    }
  } catch(e) { console.error('Error:', e); }
}
test();
