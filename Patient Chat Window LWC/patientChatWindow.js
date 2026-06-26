import { LightningElement, api, track } from 'lwc';

import getPatientDetails
    from '@salesforce/apex/PatientChatController.getPatientDetails';

import getDoctorDetails
    from '@salesforce/apex/PatientChatController.getDoctorDetails';

import publishPatientMessage
    from '@salesforce/apex/PatientEventPublisher.publishPatientMessage';

import publishPatientPresence
    from '@salesforce/apex/PatientEventPublisher.publishPatientPresence';

import { ShowToastEvent }
    from 'lightning/platformShowToastEvent';

    import getNearestAppointment
from '@salesforce/apex/PatientChatController.getNearestAppointment';

import {
    subscribe,
    unsubscribe,
    onError
} from 'lightning/empApi';

export default class PatientChatWindow extends LightningElement {

    @api recordId;

    @track patientName;
    @track doctorOnline = false;

presenceChannel =
    '/event/Presence_Status__e';

presenceSubscription =
    null;
    @track selectedDoctorId;
    @track selectedDoctorName;
    @track selectedDoctorSpecialization;
    @track nearestAppointment;
@track appointmentDoctorName;
@track appointmentDate;
@track appointmentTime;
    @track messageText = '';

    @track messages = [];
 hasUnreadMessage = false;
unreadCount = 0;
notifications = [];
showInbox = false;

    @track isChatOpen = false;

    channelName = '/event/Doctor_Message__e';

    subscription = null;

connectedCallback() {

    this.loadPatient();
    this.subscribeToNotifications();

    this.loadNearestAppointment();

    this.subscribeDoctorMessages();

    this.subscribePresenceStatus();

    this.appointmentRefreshInterval =
        setInterval(() => {

            this.loadNearestAppointment();

        }, 60000); // every 1 minute

    onError(error => {

        console.error(
            'EMP Error',
            JSON.stringify(error)
        );

    });
}

handleInboxClick() {
    this.showInbox = !this.showInbox;
     if(this.showInbox){
        this.unreadCount = 0;
        this.hasUnreadMessage = false;
    }
}

subscribeToNotifications() {

    const channelName = '/event/Doctor_Message__e';

    subscribe(channelName, -1, (response) => {

        console.log(
            'Platform Event Received',
            JSON.stringify(response)
        );

        const payload = response.data.payload;

        if (payload.Patient_Record_Id__c === this.recordId) {

            const formattedTime = payload.Message_Time__c
                ? new Date(payload.Message_Time__c).toLocaleString()
                : new Date().toLocaleString();

            this.notifications = [
                {
                    id: Date.now(),
                    doctorName: payload.Doctor_Name__c,
                    message: payload.Message__c,
                    messageTime: formattedTime
                },
                ...this.notifications
            ];

            this.hasUnreadMessage = true;

         
            if (!this.showInbox) {
                this.unreadCount++;
            }

            console.log(
                'Notifications',
                JSON.stringify(this.notifications)
            );
        }

    })
    .then((response) => {

        console.log(
            'Subscribed Successfully',
            JSON.stringify(response)
        );

    })
    .catch((error) => {

        console.error(
            'Subscription Error',
            JSON.stringify(error)
        );

    });
}



subscribePresenceStatus() {

    subscribe(
        this.presenceChannel,
        -1,
        (event) => {

            const payload =
                event.data.payload;

            if (
                !payload.Is_user_doctor__c
            ) {
                return;
            }

            if (
                payload.Record_Id__c ===
                this.selectedDoctorId
            ) {

                this.doctorOnline =
                    payload.Is_Online__c;
            }
        }
    )
    .then(response => {

        this.presenceSubscription =
            response;

        console.log(
            'Doctor Presence Subscribed'
        );
    });
}
disconnectedCallback() {

    this.publishOfflinePresence();

    if(this.subscription){
        unsubscribe(this.subscription);
    }

    if(this.presenceSubscription){
        unsubscribe(this.presenceSubscription);
    }

    if(this.appointmentRefreshInterval){
        clearInterval(
            this.appointmentRefreshInterval
        );
    }
}




async loadNearestAppointment() {

    try {

        const result =
            await getNearestAppointment({
                patientId: this.recordId
            });

        if(result){

            this.nearestAppointment =
                result;

            this.appointmentDoctorName =
                result.Doctor__r.Name;

            this.appointmentDate =
                result.Appointment_Date__c;

            this.appointmentTime =
                result.Time_Slot__c;
        }
        else{

            this.nearestAppointment = null;

            this.appointmentDoctorName = null;

            this.appointmentDate = null;

            this.appointmentTime = null;
        }
    }
    catch(error){

        console.error(error);
    }
}

get doctorStatusText() {

    return this.doctorOnline
        ? 'Online'
        : 'Offline';
}
    async loadPatient() {

        try {

            const result =
                await getPatientDetails({
                    patientId: this.recordId
                });

            this.patientName =
                result.Name;

        }
        catch (error) {

            console.error(error);

            this.showToast(
                'Error',
                'Unable to load patient',
                'error'
            );
        }
    }

    async handleOpenChat() {

        this.isChatOpen = true;

        try {

            await publishPatientPresence({

                patientId:
                    this.recordId,

                patientName:
                    this.patientName,

                isOnline:
                    true
            });

        }
        catch (error) {

            console.error(error);
        }
    }

    async publishOfflinePresence() {

        try {

            await publishPatientPresence({

                patientId:
                    this.recordId,

                patientName:
                    this.patientName,

                isOnline:
                    false
            });

        }
        catch (error) {

            console.error(error);
        }
    }

    async loadDoctorInformation() {

        if (!this.selectedDoctorId) {
            return;
        }

        try {

            const doctor =
                await getDoctorDetails({

                    doctorId:
                        this.selectedDoctorId

                });

            this.selectedDoctorSpecialization =
                doctor.Specialization__c;

        }
        catch (error) {

            console.error(error);
        }
    }

    handleMessageChange(event) {

        this.messageText =
            event.target.value;
    }

    async handleSendMessage() {

        if (!this.messageText?.trim()) {

            return;
        }

        if (!this.selectedDoctorId) {

            this.showToast(
                'Warning',
                'Doctor not connected yet.',
                'warning'
            );

            return;
        }

        try {

            await publishPatientMessage({

                patientId:
                    this.recordId,

                patientName:
                    this.patientName,

                doctorId:
                    this.selectedDoctorId,

                doctorName:
                    this.selectedDoctorName,

                messageText:
                    this.messageText

            });

            this.messages = [

                ...this.messages,

                {
                    id:
                        Date.now(),

                    sender:
                        'Patient',

                    message:
                        this.messageText,

                    cssClass:
                        'patient-message'
                }
            ];

            this.messageText = '';

            this.scrollBottom();

        }
        catch (error) {

            console.error(error);

            this.showToast(
                'Error',
                error?.body?.message ||
                'Unable to send message',
                'error'
            );
        }
    }

    handleEndChat() {

        this.publishOfflinePresence();

        this.isChatOpen = false;

        this.selectedDoctorId = null;

        this.selectedDoctorName = null;

        this.selectedDoctorSpecialization = null;

        this.messageText = '';

        this.messages = [];
    }

    subscribeDoctorMessages() {

        subscribe(
            this.channelName,
            -1,
            async (event) => {

                const payload =
                    event.data.payload;

                if (
                    payload.Patient_Record_Id__c !==
                    this.recordId
                ) {
                    return;
                }

                this.selectedDoctorId =
                    payload.Doctor_Record_Id__c;

                this.selectedDoctorName =
                    payload.Doctor_Name__c;

                    this.doctorOnline = true;

                if (
                    !this.selectedDoctorSpecialization
                ) {

                    await this.loadDoctorInformation();
                }

                this.messages = [

                    ...this.messages,

                    {
                        id:
                            Date.now(),

                        sender:
                            'Doctor',

                        message:
                            payload.Message__c,

                        cssClass:
                            'doctor-message'
                    }
                ];

                this.scrollBottom();
            }
        )
        .then(response => {

            this.subscription =
                response;

            console.log(
                'Doctor Event Subscribed'
            );

        })
        .catch(error => {

            console.error(error);

        });
    }

    scrollBottom() {

        setTimeout(() => {

            const container =
                this.template.querySelector(
                    '.chat-body'
                );

            if (container) {

                container.scrollTop =
                    container.scrollHeight;
            }

        }, 100);
    }

    showToast(
        title,
        message,
        variant
    ) {

        this.dispatchEvent(

            new ShowToastEvent({

                title,
                message,
                variant

            })

        );
    }

    get isSendDisabled() {
    return !this.selectedDoctorId;
}
get statusClass() {
    return this.doctorOnline
        ? 'online-status online'
        : 'online-status offline';
}

get statusDotClass() {
    return this.doctorOnline
        ? 'online-dot online'
        : 'online-dot offline';
}
}