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
    const patientId = patients.data[0].id;
    
    const slotsResponse = await fetch('http://localhost:3000/api/slots/available?clinicId=1&doctorId=1&fromDate=2026-04-01&toDate=2026-04-30', { headers }).then(r => r.json());
    if (!slotsResponse.data || !slotsResponse.data.items || slotsResponse.data.items.length === 0) {
      console.log('No slots available', slotsResponse);
      return;
    }
    const slotId = slotsResponse.data.items[0].slotId;
    
    const servicesResp = await fetch('http://localhost:3000/api/services?facilityId=1', { headers }).then(r => r.json());
    if (!servicesResp.data || servicesResp.data.items.length === 0) {
      console.log('No services available', servicesResp);
      return;
    }
    const serviceId = servicesResp.data.items[0].id;
    
    const appt = await fetch('http://localhost:3000/api/appointments', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        patientId: patientId.toString(),
        facilityId: '1',
        doctorId: '1',
        serviceId: serviceId.toString(),
        slotId: slotId.toString(),
        appointmentType: 'consultation',
        appointmentDate: '2026-04-20',
        appointmentTime: '08:00',
        note: 'Được tạo tự động bởi trợ lý AI để test luồng dịch vụ'
      })
    }).then(r => r.json());
    
    console.log('Appointment created:', JSON.stringify(appt));
    
    if (appt.data && appt.data.appointmentId) {
      const payment = await fetch('http://localhost:3000/api/payments', {
        method: 'POST',
        headers,
        body: JSON.stringify({
          appointmentId: appt.data.appointmentId.toString(),
          paymentMethod: 'vnpay'
        })
      }).then(r => r.json());
      console.log('Payment created:', JSON.stringify(payment));
    }
  } catch(e) { console.error('Error:', e); }
}
test();
