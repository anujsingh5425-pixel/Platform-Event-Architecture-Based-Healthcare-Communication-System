public with sharing class DoctorEventPublisher {

    @AuraEnabled
    public static String publishDoctorMessage(
        String doctorId,
        String doctorName,
        String patientId,
        String patientName,
        String messageText
    ){

        try{

            System.debug('Doctor Message Publish Started');

            if(String.isBlank(doctorId)){
                throw new AuraHandledException('Doctor Id Missing');
            }

            if(String.isBlank(patientId)){
                throw new AuraHandledException('Patient Id Missing');
            }

            if(String.isBlank(messageText)){
                throw new AuraHandledException('Message Cannot Be Empty');
            }

            String sessionId = doctorId + '_' + patientId;

            Doctor_Message__e eventRecord = new Doctor_Message__e();

            eventRecord.Doctor_Record_Id__c = doctorId;
            eventRecord.Doctor_Name__c = doctorName;

            eventRecord.Patient_Record_Id__c = patientId;
            eventRecord.Patient_Name__c = patientName;

            eventRecord.Message__c = messageText;
            eventRecord.Message_Time__c = System.now();

            eventRecord.Session_Id__c = sessionId;

            Database.SaveResult result =
                EventBus.publish(eventRecord);

            if(result.isSuccess()){

                System.debug('Doctor Message Published');

                return 'SUCCESS';
            }

            return 'FAILED';

        }catch(Exception ex){

            System.debug('Publish Error => ' + ex.getMessage());

            throw new AuraHandledException(
                ex.getMessage()
            );
        }
    }

    @AuraEnabled
    public static String publishDoctorPresence(
        String doctorId,
        String doctorName,
        Boolean isOnline
    ){

        try{

            Presence_Status__e presenceEvent =
                new Presence_Status__e();

            presenceEvent.Record_Id__c = doctorId;
            presenceEvent.Record_Name__c = doctorName;

            presenceEvent.Is_user_doctor__c = true;
            presenceEvent.Is_user_patient__c = false;

            presenceEvent.Is_Online__c = isOnline;

            if(!isOnline){
                presenceEvent.Last_Seen__c =
                    System.now();
            }

            presenceEvent.Session_Id__c =
                doctorId;

            Database.SaveResult result =
                EventBus.publish(
                    presenceEvent
                );

            if(result.isSuccess()){
                return 'SUCCESS';
            }

            return 'FAILED';

        }catch(Exception ex){

            System.debug(
                'Presence Error => ' +
                ex.getMessage()
            );

            throw new AuraHandledException(
                ex.getMessage()
            );
        }
    }
}
