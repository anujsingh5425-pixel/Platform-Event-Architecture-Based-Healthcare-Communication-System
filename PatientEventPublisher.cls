public with sharing class PatientEventPublisher {

    @AuraEnabled
    public static void publishPatientMessage(

        String patientId,
        String patientName,

        String doctorId,
        String doctorName,

        String messageText

    ) {

        if(String.isBlank(messageText)){
            return;
        }

        Patient_Message__e eventObj =
            new Patient_Message__e();

        eventObj.Patient_Record_Id__c =
            patientId;

        eventObj.Patient_Name__c =
            patientName;

        eventObj.Doctor_Record_Id__c =
            doctorId;

        eventObj.Doctor_Name__c =
            doctorName;

        eventObj.Message__c =
            messageText;

        eventObj.Message_Time__c =
            System.now();

        eventObj.Session_Id__c =
            patientId + '_' + doctorId;

        Database.SaveResult sr =
            EventBus.publish(
                eventObj
            );

        if(!sr.isSuccess()){

            throw new AuraHandledException(
                'Unable to publish patient message.'
            );
        }
    }

    @AuraEnabled
    public static void publishPatientPresence(

        String patientId,
        String patientName,

        Boolean isOnline

    ) {

        Presence_Status__e presence =
            new Presence_Status__e();

        presence.Record_Id__c =
            patientId;

        presence.Record_Name__c =
            patientName;

        presence.Is_Online__c =
            isOnline;

        presence.Is_user_patient__c =
            true;

        presence.Is_user_doctor__c =
            false;

        presence.Last_Seen__c =
            System.now();

        presence.Session_Id__c =
            patientId;

        Database.SaveResult sr =
            EventBus.publish(
                presence
            );

        if(!sr.isSuccess()){

            throw new AuraHandledException(
                'Unable to publish presence status.'
            );
        }
    }
}
