public with sharing class PatientChatController {

    @AuraEnabled(cacheable=true)
    public static Patient__c getPatientDetails(
        Id patientId
    ) {

        if(patientId == null){
            return null;
        }

        return [

            SELECT
                Id,
                Name,
                Doctor__c

            FROM Patient__c

            WHERE Id = :patientId

            LIMIT 1
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Doctor__c getDoctorDetails(
        Id doctorId
    ) {

        if(doctorId == null){
            return null;
        }

        return [

            SELECT
                Id,
                Name,
                Specialization__c

            FROM Doctor__c

            WHERE Id = :doctorId

            LIMIT 1
        ];
    }



@AuraEnabled
public static Appointment__c getNearestAppointment(Id patientId){


    System.debug('Patient Id : ' + patientId);

    if(patientId == null){

        System.debug('Patient Id is NULL');
        return null;
    }

    Date todayDate = System.today();

    System.debug('Today Date : ' + todayDate);

    List<Appointment__c> appointments = [

        SELECT
            Id,
            Name,
            Appointment_Date__c,
            Time_Slot__c,
            Doctor__c,
            Doctor__r.Name,
            Status__c
        FROM Appointment__c
        WHERE Patient__c = :patientId
        AND Appointment_Date__c >= :todayDate
        ORDER BY Appointment_Date__c ASC
    ];

    System.debug('Total Appointments Found : ' + appointments.size());

    if(appointments.isEmpty()){

        System.debug('No Appointment Found');
        return null;
    }


    Datetime nowUTC = Datetime.now();
    System.debug('Current UTC: ' + nowUTC);

    Appointment__c nearestAppointment;
    Long smallestDifference;

    for(Appointment__c app : appointments){

        System.debug(' ');
        System.debug('---------------- APPOINTMENT START ----------------');

        System.debug('Appointment Id : ' + app.Id);
        System.debug('Appointment Name : ' + app.Name);
        System.debug('Appointment Date : ' + app.Appointment_Date__c);
        System.debug('Appointment Time Slot : ' + app.Time_Slot__c);
        System.debug('Doctor : ' + app.Doctor__r.Name);

        if(String.isBlank(app.Time_Slot__c)){

            System.debug('SKIPPED : Time Slot Blank');
            continue;
        }

        try{

            Time appointmentTime = convertTimeSlot(app.Time_Slot__c);

            System.debug('Converted Time : ' + appointmentTime);

            
            Integer hourUTC = appointmentTime.hour() - 5;
            Integer minuteUTC = appointmentTime.minute() - 30;
            Date dateUTC = app.Appointment_Date__c;
            
            if(minuteUTC < 0) {
                minuteUTC += 60;
                hourUTC -= 1;
            }
            if(hourUTC < 0) {
                hourUTC += 24;
                dateUTC = dateUTC.addDays(-1);
            }
            
            Datetime appointmentUTC = Datetime.newInstanceGmt(
                dateUTC.year(), 
                dateUTC.month(), 
                dateUTC.day(), 
                hourUTC, 
                minuteUTC, 
                0
            );

            System.debug('Appointment UTC: ' + appointmentUTC);
            System.debug('Appointment Milliseconds: ' + appointmentUTC.getTime());

          
            if(appointmentUTC <= nowUTC){

                System.debug('SKIPPED : Appointment Already Expired');
                continue;
            }

            Long difference = appointmentUTC.getTime() - nowUTC.getTime();

            System.debug('Difference Milliseconds : ' + difference);
            System.debug('Difference Minutes : ' + (difference / 1000 / 60));

            Long twentyFourHours = 24L * 60L * 60L * 1000L;

            System.debug('24 Hours Milliseconds : ' + twentyFourHours);

            if(difference > twentyFourHours){

                System.debug('SKIPPED : More Than 24 Hours Away');
                continue;
            }

            if(smallestDifference == null || difference < smallestDifference){

                smallestDifference = difference;
                nearestAppointment = app;

                
                System.debug('Nearest Appointment Id : ' + app.Id);
                System.debug('Nearest Doctor : ' + app.Doctor__r.Name);
                System.debug('Nearest Time Slot : ' + app.Time_Slot__c);
            }

            

        }
        catch(Exception e){

            System.debug('ERROR Processing Appointment');
            System.debug('Time Slot : ' + app.Time_Slot__c);
            System.debug('Exception : ' + e.getMessage());
        }
    }

   

    if(nearestAppointment != null){

        System.debug(' Final Appointment Id : ' + nearestAppointment.Id);
        System.debug('Final Doctor : ' + nearestAppointment.Doctor__r.Name);
        System.debug(' Final Date : ' + nearestAppointment.Appointment_Date__c);
        System.debug(' Final Time Slot : ' + nearestAppointment.Time_Slot__c);
    }
    else{

        System.debug(' NO NEAREST APPOINTMENT FOUND');
    }



    return nearestAppointment;
}

private static Time convertTimeSlot(
    String timeSlot
){

  
   

    System.debug(
        'Original Time Slot : '
        + timeSlot
    );

    timeSlot =
        timeSlot.trim().toUpperCase();

    System.debug(
        'After Trim/Upper : '
        + timeSlot
    );

    Boolean isPM =
        timeSlot.contains('PM');

    Boolean isAM =
        timeSlot.contains('AM');

    System.debug(
        'isPM : '
        + isPM
    );

    System.debug(
        'isAM : '
        + isAM
    );

    timeSlot =
        timeSlot.replace('AM','')
                .replace('PM','')
                .trim();

    System.debug(
        'Time Without AM/PM : '
        + timeSlot
    );

    List<String> parts =
        timeSlot.split(':');

    System.debug(
        'Hour Part : '
        + parts[0]
    );

    System.debug(
        'Minute Part : '
        + parts[1]
    );

    Integer hour =
        Integer.valueOf(parts[0]);

    Integer minute =
        Integer.valueOf(parts[1]);

    System.debug(
        'Parsed Hour : '
        + hour
    );

    System.debug(
        'Parsed Minute : '
        + minute
    );

    if(isPM && hour != 12){

        hour += 12;
    }

    if(isAM && hour == 12){

        hour = 0;
    }

    System.debug(
        '24 Hour Format Hour : '
        + hour
    );

    Time finalTime =
        Time.newInstance(
            hour,
            minute,
            0,
            0
        );

    System.debug(
        'Final Time : '
        + finalTime
    );

    

    return finalTime;
}
}
