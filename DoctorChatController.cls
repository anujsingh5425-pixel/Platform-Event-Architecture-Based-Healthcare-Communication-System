public with sharing class DoctorChatController {

    @AuraEnabled(cacheable=true)
    public static Doctor__c getDoctorDetails(Id doctorId) {

        System.debug('Doctor Id Received => ' + doctorId);

        if(doctorId == null){
            throw new AuraHandledException('Doctor Id is required');
        }

        List<Doctor__c> doctors = [
            SELECT Id,
                   Name,
                   Doctor_Name__c,
                   Specialization__c
            FROM Doctor__c
            WHERE Id = :doctorId
            LIMIT 1
        ];

        if(doctors.isEmpty()){
            throw new AuraHandledException('Doctor not found');
        }

        return doctors[0];
    }

    @AuraEnabled(cacheable=true)
    public static Patient__c getPatientDetails(Id patientId){

        System.debug('Patient Id Received => ' + patientId);

        if(patientId == null){
            throw new AuraHandledException('Patient Id is required');
        }

        List<Patient__c> patients = [
            SELECT Id,
                   Name
            FROM Patient__c
            WHERE Id = :patientId
            LIMIT 1
        ];

        if(patients.isEmpty()){
            throw new AuraHandledException('Patient not found');
        }

        return patients[0];
    }

   
    @AuraEnabled
    public static Appointment__c getNearestAppointment(Id doctorId){

        
        System.debug('Doctor Id : ' + doctorId);

        if(doctorId == null){
            System.debug('Doctor Id is NULL');
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
                Patient__c,
                Patient__r.Name,
                Doctor__c,
                Doctor__r.Name,
                Status__c
            FROM Appointment__c
            WHERE Doctor__c = :doctorId
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
           

            System.debug('Appointment Id : ' + app.Id);
            System.debug('Appointment Name : ' + app.Name);
            System.debug('Appointment Date : ' + app.Appointment_Date__c);
            System.debug('Appointment Time Slot : ' + app.Time_Slot__c);
            System.debug('Patient : ' + app.Patient__r.Name);
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

                    System.debug(' NEW NEAREST APPOINTMENT SELECTED');
                    System.debug('Nearest Appointment Id : ' + app.Id);
                    System.debug('Nearest Patient : ' + app.Patient__r.Name);
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
            System.debug(' Final Patient : ' + nearestAppointment.Patient__r.Name);
            System.debug(' Final Date : ' + nearestAppointment.Appointment_Date__c);
            System.debug(' Final Time Slot : ' + nearestAppointment.Time_Slot__c);
        }
        else{

            System.debug(' NO NEAREST APPOINTMENT FOUND');
        }

       

        return nearestAppointment;
    }

   
    private static Time convertTimeSlot(String timeSlot){

        System.debug(' ');
     

        System.debug('Original Time Slot : ' + timeSlot);

        timeSlot = timeSlot.trim().toUpperCase();

        System.debug('After Trim/Upper : ' + timeSlot);

        Boolean isPM = timeSlot.contains('PM');
        Boolean isAM = timeSlot.contains('AM');

        System.debug('isPM : ' + isPM);
        System.debug('isAM : ' + isAM);

        timeSlot = timeSlot.replace('AM','').replace('PM','').trim();

        System.debug('Time Without AM/PM : ' + timeSlot);

        List<String> parts = timeSlot.split(':');

        System.debug('Hour Part : ' + parts[0]);
        System.debug('Minute Part : ' + parts[1]);

        Integer hour = Integer.valueOf(parts[0]);
        Integer minute = Integer.valueOf(parts[1]);

        System.debug('Parsed Hour : ' + hour);
        System.debug('Parsed Minute : ' + minute);

        if(isPM && hour != 12){
            hour += 12;
        }

        if(isAM && hour == 12){
            hour = 0;
        }

        System.debug('24 Hour Format Hour : ' + hour);

        Time finalTime = Time.newInstance(hour, minute, 0, 0);

        System.debug('Final Time : ' + finalTime);
      

        return finalTime;
    }

    
    
        @AuraEnabled
    public static Map<String, Object> getPatientReport(String patientId) {
       
        System.debug('Input Patient Id: ' + patientId);
        
        try {
            if (String.isBlank(patientId)) {
                System.debug('ERROR: Patient Id is blank or null');
                throw new AuraHandledException('Patient Id is required');
            }
            
            Map<String, Object> result = new Map<String, Object>();
            System.debug('Result map created successfully');
            
           
            System.debug('Calling getPatientRecord method...');
            Patient__c patient = getPatientRecord(patientId);
            
            if (patient == null) {
                System.debug('ERROR: Patient not found with Id: ' + patientId);
                throw new AuraHandledException('Patient not found');
            }
            
            System.debug('Patient record retrieved successfully');
            System.debug('Patient Name: ' + patient.Name);
            System.debug('Patient Id: ' + patient.Id);
            
           
            System.debug('=== Setting Patient Profile ===');
            result.put('patientName', patient.Name);
            System.debug('patientName: ' + (patient.Name != null ? patient.Name : 'NULL'));
            
            result.put('patientId', patient.Id);
            System.debug('patientId: ' + patient.Id);
            
            if (patient.Age__c != null) {
                result.put('age', Integer.valueOf(patient.Age__c));
                System.debug('age: ' + patient.Age__c);
            } else {
                result.put('age', null);
                System.debug('age: NULL');
            }
            
            result.put('gender', patient.Gender__c);
            System.debug('gender: ' + (patient.Gender__c != null ? patient.Gender__c : 'NULL'));
            
            result.put('phone', patient.Phone__c);
            System.debug('phone: ' + (patient.Phone__c != null ? patient.Phone__c : 'NULL'));
            
            result.put('email', patient.Email__c);
            System.debug('email: ' + (patient.Email__c != null ? patient.Email__c : 'NULL'));
            
            
            System.debug('=== Setting Health Summary ===');
            result.put('riskLevel', patient.Risk_Level__c);
            System.debug('riskLevel: ' + (patient.Risk_Level__c != null ? patient.Risk_Level__c : 'NULL'));
            
            result.put('severity', patient.Severity__c);
            System.debug('severity: ' + (patient.Severity__c != null ? patient.Severity__c : 'NULL'));
            
            result.put('symptoms', patient.Symptoms__c);
            System.debug('symptoms: ' + (patient.Symptoms__c != null ? patient.Symptoms__c : 'NULL'));
            
            result.put('existingConditions', patient.Existing_Conditions__c);
            System.debug('existingConditions: ' + (patient.Existing_Conditions__c != null ? patient.Existing_Conditions__c : 'NULL'));
            
            result.put('allergies', patient.Allergies__c);
            System.debug('allergies: ' + (patient.Allergies__c != null ? patient.Allergies__c : 'NULL'));
            
            result.put('currentMedications', patient.Current_Medications__c);
            System.debug('currentMedications: ' + (patient.Current_Medications__c != null ? patient.Current_Medications__c : 'NULL'));
            
           
            
            if (patient.BP_Level__c != null) {
                result.put('bloodPressure', String.valueOf(patient.BP_Level__c));
                System.debug('bloodPressure: ' + patient.BP_Level__c);
            } else {
                result.put('bloodPressure', null);
                System.debug('bloodPressure: NULL');
            }
            
            if (patient.Sugar_Level__c != null) {
                result.put('sugarLevel', String.valueOf(patient.Sugar_Level__c));
                System.debug('sugarLevel: ' + patient.Sugar_Level__c);
            } else {
                result.put('sugarLevel', null);
                System.debug('sugarLevel: NULL');
            }
            
            if (patient.Heart_Rate__c != null) {
                result.put('heartRate', String.valueOf(patient.Heart_Rate__c));
                System.debug('heartRate: ' + patient.Heart_Rate__c);
            } else {
                result.put('heartRate', null);
                System.debug('heartRate: NULL');
            }
            
            result.put('bodyTemperature', patient.Body_Temperature__c);
            System.debug('bodyTemperature: ' + (patient.Body_Temperature__c != null ? patient.Body_Temperature__c : 'NULL'));
            
            if (patient.Oxygen_Saturation__c != null) {
                result.put('oxygenSaturation', String.valueOf(patient.Oxygen_Saturation__c));
                System.debug('oxygenSaturation: ' + patient.Oxygen_Saturation__c);
            } else {
                result.put('oxygenSaturation', null);
                System.debug('oxygenSaturation: NULL');
            }
            
            if (patient.BMI__c != null) {
                result.put('bmi', String.valueOf(patient.BMI__c));
                System.debug('bmi: ' + patient.BMI__c);
            } else {
                result.put('bmi', null);
                System.debug('bmi: NULL');
            }
            
            if (patient.Height__c != null) {
                result.put('height', String.valueOf(patient.Height__c));
                System.debug('height: ' + patient.Height__c);
            } else {
                result.put('height', null);
                System.debug('height: NULL');
            }
            
            if (patient.Weight__c != null) {
                result.put('weight', String.valueOf(patient.Weight__c));
                System.debug('weight: ' + patient.Weight__c);
            } else {
                result.put('weight', null);
                System.debug('weight: NULL');
            }
            
            if (patient.Cholesterol__c != null) {
                result.put('cholesterol', String.valueOf(patient.Cholesterol__c));
                System.debug('cholesterol: ' + patient.Cholesterol__c);
            } else {
                result.put('cholesterol', null);
                System.debug('cholesterol: NULL');
            }
            
        
            System.debug('=== Setting AI Assessment ===');
            result.put('aiRiskPrediction', patient.AI_Risk_Predicted__c);
            System.debug('aiRiskPrediction: ' + (patient.AI_Risk_Predicted__c != null ? String.valueOf(patient.AI_Risk_Predicted__c) : 'NULL'));
            
            if (patient.AI_Risk_Predicted_Score__c != null) {
                result.put('aiRiskScore', patient.AI_Risk_Predicted_Score__c);
                System.debug('aiRiskScore: ' + patient.AI_Risk_Predicted_Score__c);
            } else {
                result.put('aiRiskScore', null);
                System.debug('aiRiskScore: NULL');
            }
            
            result.put('suggestedDoctorType', patient.Suggested_Doctor_Type__c);
            System.debug('suggestedDoctorType: ' + (patient.Suggested_Doctor_Type__c != null ? patient.Suggested_Doctor_Type__c : 'NULL'));
            
            result.put('recommendation', patient.Recommendation__c);
            System.debug('recommendation: ' + (patient.Recommendation__c != null ? patient.Recommendation__c : 'NULL'));
            
            result.put('aiExplanation', patient.AI_Explanation__c);
            System.debug('aiExplanation: ' + (patient.AI_Explanation__c != null ? patient.AI_Explanation__c : 'NULL'));
            
        
            System.debug('=== Setting Lifestyle ===');
            result.put('smokingStatus', patient.Smoking_Status__c);
            System.debug('smokingStatus: ' + (patient.Smoking_Status__c != null ? patient.Smoking_Status__c : 'NULL'));
            
            result.put('alcoholConsumption', patient.Alcohol_Consumption__c);
            System.debug('alcoholConsumption: ' + (patient.Alcohol_Consumption__c != null ? patient.Alcohol_Consumption__c : 'NULL'));
            
         
            System.debug('=== Fetching Medical Reports ===');
            List<Map<String, Object>> medicalReports = getMedicalReports(patientId);
            result.put('medicalReports', medicalReports);
            System.debug('Total Medical Reports fetched: ' + (medicalReports != null ? medicalReports.size() : 0));
            
        
            System.debug('=== Fetching Medication Tracking ===');
            List<Map<String, Object>> medicationTracking = getMedicationTracking(patientId);
            result.put('medicationTracking', medicationTracking);
            System.debug('Total Medication Tracking records fetched: ' + (medicationTracking != null ? medicationTracking.size() : 0));
            
           
            System.debug('=== Setting MRN Number ===');
            if (medicalReports != null && !medicalReports.isEmpty()) {
                Map<String, Object> latestReport = medicalReports[0];
                result.put('mrnNumber', latestReport.get('mrnNumber'));
                System.debug('MRN Number set from latest report: ' + latestReport.get('mrnNumber'));
            } else {
                result.put('mrnNumber', null);
                System.debug('No medical reports found, MRN Number remains NULL');
            }
            
            System.debug('=== FINAL RESULT DATA ===');
            System.debug(JSON.serializePretty(result));
            System.debug('=== END: getPatientReport (SUCCESS) ===');
            
            return result;
            
        } catch (Exception e) {
            System.debug('=== ERROR in getPatientReport ===');
            System.debug('Error Message: ' + e.getMessage());
            System.debug('Error Type: ' + e.getTypeName());
            System.debug('Error Line: ' + e.getLineNumber());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error fetching patient report: ' + e.getMessage());
        }
    }
    
    private static Patient__c getPatientRecord(String patientId) {
        System.debug('=== START: getPatientRecord ===');
        System.debug('Searching for patient with Id: ' + patientId);
        
        try {
            List<Patient__c> patients = [
                SELECT Id, Name, Age__c, Gender__c, Phone__c, Email__c,
                       Risk_Level__c, Severity__c, Symptoms__c, Existing_Conditions__c,
                       Allergies__c, Current_Medications__c,
                       BP_Level__c, Sugar_Level__c, Heart_Rate__c, Body_Temperature__c,
                       Oxygen_Saturation__c, BMI__c, Height__c, Weight__c, Cholesterol__c,
                       AI_Risk_Predicted__c, AI_Risk_Predicted_Score__c,
                       Suggested_Doctor_Type__c, Recommendation__c, AI_Explanation__c,
                       Smoking_Status__c, Alcohol_Consumption__c
                FROM Patient__c
                WHERE Id = :patientId
                LIMIT 1
            ];
            
            System.debug('Query returned ' + patients.size() + ' records');
            
            if (patients.isEmpty()) {
                System.debug('No patient found with Id: ' + patientId);
                System.debug('=== END: getPatientRecord (NO RECORD FOUND) ===');
                return null;
            }
            
            Patient__c patient = patients[0];
            System.debug('Patient found:');
            System.debug('  - Name: ' + patient.Name);
            System.debug('  - Id: ' + patient.Id);
            System.debug('  - Age: ' + patient.Age__c);
            System.debug('  - Gender: ' + patient.Gender__c);
            System.debug('  - Risk Level: ' + patient.Risk_Level__c);
            System.debug('  - Severity: ' + patient.Severity__c);
            System.debug('  - BMI: ' + patient.BMI__c);
            System.debug('  - AI Risk Score: ' + patient.AI_Risk_Predicted_Score__c);
            
            
            System.debug('=== NULL FIELD CHECK ===');
            if (patient.Name == null) System.debug('Name is NULL');
            if (patient.Age__c == null) System.debug('Age__c is NULL');
            if (patient.Gender__c == null) System.debug('Gender__c is NULL');
            if (patient.Phone__c == null) System.debug('Phone__c is NULL');
            if (patient.Email__c == null) System.debug('Email__c is NULL');
            if (patient.Risk_Level__c == null) System.debug('Risk_Level__c is NULL');
            if (patient.Severity__c == null) System.debug('Severity__c is NULL');
            if (patient.Symptoms__c == null) System.debug('Symptoms__c is NULL');
            if (patient.Existing_Conditions__c == null) System.debug('Existing_Conditions__c is NULL');
            if (patient.Allergies__c == null) System.debug('Allergies__c is NULL');
            if (patient.Current_Medications__c == null) System.debug('Current_Medications__c is NULL');
            if (patient.BP_Level__c == null) System.debug('BP_Level__c is NULL');
            if (patient.Sugar_Level__c == null) System.debug('Sugar_Level__c is NULL');
            if (patient.Heart_Rate__c == null) System.debug('Heart_Rate__c is NULL');
            if (patient.Body_Temperature__c == null) System.debug('Body_Temperature__c is NULL');
            if (patient.Oxygen_Saturation__c == null) System.debug('Oxygen_Saturation__c is NULL');
            if (patient.BMI__c == null) System.debug('BMI__c is NULL');
            if (patient.Height__c == null) System.debug('Height__c is NULL');
            if (patient.Weight__c == null) System.debug('Weight__c is NULL');
            if (patient.Cholesterol__c == null) System.debug('Cholesterol__c is NULL');
            if (patient.AI_Risk_Predicted__c == null) System.debug('AI_Risk_Predicted__c is NULL');
            if (patient.AI_Risk_Predicted_Score__c == null) System.debug('AI_Risk_Predicted_Score__c is NULL');
            if (patient.Suggested_Doctor_Type__c == null) System.debug('Suggested_Doctor_Type__c is NULL');
            if (patient.Recommendation__c == null) System.debug('Recommendation__c is NULL');
            if (patient.AI_Explanation__c == null) System.debug('AI_Explanation__c is NULL');
            if (patient.Smoking_Status__c == null) System.debug('Smoking_Status__c is NULL');
            if (patient.Alcohol_Consumption__c == null) System.debug('Alcohol_Consumption__c is NULL');
            
            System.debug('=== END: getPatientRecord (SUCCESS) ===');
            return patient;
            
        } catch (Exception e) {
            System.debug('=== ERROR in getPatientRecord ===');
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }
    
    private static List<Map<String, Object>> getMedicalReports(String patientId) {
        System.debug('=== START: getMedicalReports ===');
        System.debug('Fetching medical reports for patient: ' + patientId);
        
        try {
            List<Map<String, Object>> reports = new List<Map<String, Object>>();
            
            List<Medical_Report__c> medicalReports = [
                SELECT Id, Name, Report_Date__c, BP_Level__c, Sugar_Level__c, Notes__c
                FROM Medical_Report__c
                WHERE Patient__c = :patientId
                ORDER BY Report_Date__c DESC
                LIMIT 50
            ];
            
            System.debug('Query returned ' + medicalReports.size() + ' medical reports');
            
            if (medicalReports.isEmpty()) {
                System.debug('No medical reports found for patient');
                System.debug('=== END: getMedicalReports (NO RECORDS) ===');
                return reports;
            }
            
            Integer index = 0;
            for (Medical_Report__c report : medicalReports) {
                index++;
                System.debug('Processing report #' + index);
                System.debug('  - Name: ' + report.Name);
                System.debug('  - Report Date: ' + report.Report_Date__c);
                System.debug('  - BP: ' + report.BP_Level__c);
                System.debug('  - Sugar: ' + report.Sugar_Level__c);
                System.debug('  - Notes: ' + report.Notes__c);
                
                Map<String, Object> reportMap = new Map<String, Object>();
                reportMap.put('mrnNumber', report.Name);
                
                
                if (report.Report_Date__c != null) {
                    reportMap.put('reportDate', Date.valueOf(report.Report_Date__c));
                    System.debug('  - reportDate: ' + report.Report_Date__c);
                } else {
                    reportMap.put('reportDate', null);
                    System.debug('  - WARNING: Report_Date__c is NULL');
                }
            
                if (report.BP_Level__c != null) {
                    reportMap.put('bloodPressure', String.valueOf(report.BP_Level__c));
                    System.debug('  - bloodPressure: ' + report.BP_Level__c);
                } else {
                    reportMap.put('bloodPressure', null);
                    System.debug('  - bloodPressure: NULL');
                }
                
                if (report.Sugar_Level__c != null) {
                    reportMap.put('sugarLevel', String.valueOf(report.Sugar_Level__c));
                    System.debug('  - sugarLevel: ' + report.Sugar_Level__c);
                } else {
                    reportMap.put('sugarLevel', null);
                    System.debug('  - sugarLevel: NULL');
                }
                
                reportMap.put('notes', report.Notes__c);
                System.debug('  - notes: ' + (report.Notes__c != null ? report.Notes__c : 'NULL'));
                
                reports.add(reportMap);
            }
            
            System.debug('Total reports processed: ' + reports.size());
            System.debug('=== END: getMedicalReports (SUCCESS) ===');
            return reports;
            
        } catch (Exception e) {
            System.debug('=== ERROR in getMedicalReports ===');
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }
    
    private static List<Map<String, Object>> getMedicationTracking(String patientId) {
        System.debug('=== START: getMedicationTracking ===');
        System.debug('Fetching medication tracking for patient: ' + patientId);
        
        try {
            List<Map<String, Object>> medications = new List<Map<String, Object>>();
            
            List<Medication_Tracking__c> medTrackings = [
                SELECT Id, Medicine_Name__c, Dosage__c, Taken_Today__c, Last_Taken_Date__c
                FROM Medication_Tracking__c
                WHERE Patient__c = :patientId
                ORDER BY CreatedDate DESC
                LIMIT 20
            ];
            
            System.debug('Query returned ' + medTrackings.size() + ' medication tracking records');
            
            if (medTrackings.isEmpty()) {
                System.debug('No medication tracking records found for patient');
                System.debug('=== END: getMedicationTracking (NO RECORDS) ===');
                return medications;
            }
            
            Integer index = 0;
            for (Medication_Tracking__c med : medTrackings) {
                index++;
                System.debug('Processing medication #' + index);
                System.debug('  - Medicine Name: ' + med.Medicine_Name__c);
                System.debug('  - Dosage: ' + med.Dosage__c);
                System.debug('  - Taken Today: ' + med.Taken_Today__c);
                System.debug('  - Last Taken Date: ' + med.Last_Taken_Date__c);
                
                Map<String, Object> medMap = new Map<String, Object>();
                medMap.put('medicineName', med.Medicine_Name__c);
                System.debug('  - medicineName: ' + (med.Medicine_Name__c != null ? med.Medicine_Name__c : 'NULL'));
                
                medMap.put('dosage', med.Dosage__c);
                System.debug('  - dosage: ' + (med.Dosage__c != null ? med.Dosage__c : 'NULL'));
                
                medMap.put('takenToday', med.Taken_Today__c);
                System.debug('  - takenToday: ' + (med.Taken_Today__c != null ? String.valueOf(med.Taken_Today__c) : 'NULL'));
                
                medMap.put('lastTakenDate', med.Last_Taken_Date__c);
                System.debug('  - lastTakenDate: ' + (med.Last_Taken_Date__c != null ? String.valueOf(med.Last_Taken_Date__c) : 'NULL'));
                
                medications.add(medMap);
            }
            
            System.debug('Total medications processed: ' + medications.size());
            System.debug('=== END: getMedicationTracking (SUCCESS) ===');
            return medications;
            
        } catch (Exception e) {
            System.debug('=== ERROR in getMedicationTracking ===');
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw e;
        }
    }

}
