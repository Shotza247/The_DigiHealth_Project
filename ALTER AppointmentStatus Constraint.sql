ALTER TABLE Appointment
ADD CONSTRAINT chk_appointment_status
CHECK (
    AppointmentStatus IN (
        'Scheduled',
        'Completed',
        'Cancelled'
    )
);