import { LightningElement, api, track } from 'lwc';

import getDoctorDetails
    from '@salesforce/apex/DoctorChatController.getDoctorDetails';

import getPatientDetails
    from '@salesforce/apex/DoctorChatController.getPatientDetails';

import publishDoctorMessage
    from '@salesforce/apex/DoctorEventPublisher.publishDoctorMessage';

import publishDoctorPresence
    from '@salesforce/apex/DoctorEventPublisher.publishDoctorPresence';

     import getNearestAppointment
from '@salesforce/apex/DoctorChatController.getNearestAppointment';

import { ShowToastEvent }
    from 'lightning/platformShowToastEvent';

    import getPatientReport from '@salesforce/apex/DoctorChatController.getPatientReport';

import {
    subscribe,
    unsubscribe,
    onError
} from 'lightning/empApi';

export default class DoctorChatWindow extends LightningElement {

    @api recordId;
@track nearestAppointment;
    @track doctorName;
    @track specialization;
@track appointmentPatientName; 
    @track patientSelected = false;
 @track showReportDrawer = false;  
@track isReportLoading = false;  
@track reportError = null;        
    @track selectedPatientId;
    @track selectedPatientName;

    @track messageText = '';

    @track messages = [];

     @api patientId;
    @track reportData = {};
    @track isLoading = false;
    @track error = null;
    @track expandedSections = {
        patientProfile: true,
        healthSummary: false,
        currentVitals: false,
        aiAssessment: false,
        lifestyle: false,
        medicalReports: false,
        medicationTracking: false
    };


@track patientOnline = false;

presenceChannel =
    '/event/Presence_Status__e';

presenceSubscription =
    null;
    @track isChatOpen = false;

    channelName = '/event/Patient_Message__e';

    subscription = null;

   connectedCallback() {

    this.loadDoctor();
    this.loadNearestAppointment();

    this.subscribePatientMessages();

    this.subscribePresenceStatus();
            this.loadPatientReport();

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

    disconnectedCallback() {

        if(this.presenceSubscription){

    unsubscribe(
        this.presenceSubscription

    );
     if(this.appointmentRefreshInterval){
        clearInterval(
            this.appointmentRefreshInterval
        );
    }
}
    }


    async loadNearestAppointment() {
    try {
        console.log('Loading nearest appointment for Doctor ID:', this.recordId);
        
        const result = await getNearestAppointment({
            doctorId: this.recordId
        });

        if(result){
            this.nearestAppointment = result;
            
           
            this.appointmentPatientName = result.Patient__r ? result.Patient__r.Name : 'Patient';
            
           
            this.appointmentDate = result.Appointment_Date__c;
            this.appointmentTime = result.Time_Slot__c;
            
            console.log(' Appointment Loaded:', {
                patientName: this.appointmentPatientName,
                time: this.appointmentTime
            });
        } else {
            this.nearestAppointment = null;
            this.appointmentPatientName = null;
            this.appointmentDate = null;
            this.appointmentTime = null;
        }
    }
    catch(error){
        console.error('Error loading appointment:', error);
    }
    console.log('Full Result:', JSON.stringify(result));
console.log('Patient Name:', result.Patient__r?.Name);
console.log('Time:', result.Time_Slot__c);
}


    subscribePresenceStatus() {

    subscribe(
        this.presenceChannel,
        -1,
        (event) => {

            const payload =
                event.data.payload;

            if (
                !payload.Is_user_patient__c
            ) {
                return;
            }

            if (
                payload.Record_Id__c ===
                this.selectedPatientId
            ) {

                this.patientOnline =
                    payload.Is_Online__c;
            }
        }
    )
    .then(response => {

        this.presenceSubscription =
            response;

        console.log(
            'Presence Subscribed'
        );
    });
}

get patientStatusText() {

    return this.patientOnline
        ? 'Online'
        : 'Offline';
}

    async loadDoctor() {

        try {

            const result =
                await getDoctorDetails({
                    doctorId: this.recordId
                });

            this.doctorName =
                result.Name;

            this.specialization =
                result.Specialization__c;

        }
        catch (error) {

            console.error(error);

            this.showToast(
                'Error',
                error?.body?.message ||
                'Unable to load doctor',
                'error'
            );
        }
    }

    async publishOfflinePresence() {

        try {

            await publishDoctorPresence({

                doctorId:
                    this.recordId,

                doctorName:
                    this.doctorName,

                isOnline:
                    false

            });

        }
        catch (error) {

            console.error(error);

        }
    }

    async handleOpenChat() {

        this.isChatOpen = true;

        try {

            await publishDoctorPresence({

                doctorId:
                    this.recordId,

                doctorName:
                    this.doctorName,

                isOnline:
                    true

            });

        }
        catch (error) {

            console.error(error);

        }
    }

    async handlePatientChange(event) {

        const patientId =
            event.detail.recordId ||
            event.detail.value;

        if (!patientId) {
            return;
        }

        try {

            const patient =
                await getPatientDetails({

                    patientId:
                        patientId

                });

            this.selectedPatientId =
                patient.Id;

            this.selectedPatientName =
                patient.Name;

            this.patientSelected =
                true;

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

    handleMessageChange(event) {

        this.messageText =
            event.target.value;
    }

    async handleSendMessage() {

        if (!this.messageText?.trim()) {

            return;

        }

        if (!this.selectedPatientId) {

            this.showToast(
                'Warning',
                'Please select patient first',
                'warning'
            );

            return;
        }

        try {

            await publishDoctorMessage({

                doctorId:
                    this.recordId,

                doctorName:
                    this.doctorName,

                patientId:
                    this.selectedPatientId,

                patientName:
                    this.selectedPatientName,

                messageText:
                    this.messageText

            });

            this.messages = [

                ...this.messages,

                {
                    id:
                        Date.now(),

                    sender:
                        'Doctor',

                    message:
                        this.messageText,

                    cssClass:
                        'doctor-message'
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
                'Failed to send message',
                'error'
            );
        }
    }

    handleEndChat() {

        this.publishOfflinePresence();

        this.isChatOpen = false;

        this.patientSelected = false;

        this.selectedPatientId = null;

        this.selectedPatientName = null;

        this.messageText = '';

        this.messages = [];
    }

    subscribePatientMessages() {

        subscribe(
            this.channelName,
            -1,
            (event) => {

                const payload =
                    event.data.payload;

                if (
                    payload.Doctor_Record_Id__c !==
                    this.recordId
                ) {
                    return;
                }

                this.messages = [

                    ...this.messages,

                    {
                        id:
                            Date.now(),

                        sender:
                            'Patient',

                        message:
                            payload.Message__c,

                        cssClass:
                            'patient-message'
                    }
                ];

                this.scrollBottom();
            }
        )
        .then(response => {

            this.subscription =
                response;

            console.log(
                'Patient Event Subscribed'
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

    get statusClass() {
    return this.patientOnline
        ? 'online-status online'
        : 'online-status offline';
}

get statusDotClass() {
    return this.patientOnline
        ? 'online-dot online'
        : 'online-dot offline';
}




  loadPatientReport() {
        if (!this.patientId) return;
        
        this.isLoading = true;
        
        getPatientReport({ patientId: this.patientId })
            .then(result => {
                this.reportData = result;
                this.isLoading = false;
                this.autoExpandSections();
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error:', error);
            });
    }

    autoExpandSections() {
        const data = this.reportData;
        
        this.expandedSections.patientProfile = !!(data.patientName || data.patientId || data.mrnNumber);
        this.expandedSections.healthSummary = !!(data.riskLevel || data.severity || data.symptoms);
        this.expandedSections.currentVitals = !!(data.bloodPressure || data.sugarLevel || data.heartRate);
        this.expandedSections.aiAssessment = !!(data.aiRiskPrediction || data.aiRiskScore);
        this.expandedSections.lifestyle = !!(data.smokingStatus || data.alcoholConsumption);
        this.expandedSections.medicalReports = data.medicalReports && data.medicalReports.length > 0;
        this.expandedSections.medicationTracking = data.medicationTracking && data.medicationTracking.length > 0;
    }

    toggleSection(event) {
        const section = event.currentTarget.dataset.section;
        if (section) {
            this.expandedSections[section] = !this.expandedSections[section];
        }
    }

    @api closeDrawer() {
        
        this.reportData = {};
        this.isLoading = false;
        
       
        this.expandedSections = {
            patientProfile: true,
            healthSummary: false,
            currentVitals: false,
            aiAssessment: false,
            lifestyle: false,
            medicalReports: false,
            medicationTracking: false
        };
        
        
        this.patientId = null;
    }

    get showPatientProfile() {
        const data = this.reportData;
        return this.expandedSections.patientProfile && 
               !!(data.patientName || data.patientId || data.mrnNumber || data.age || data.gender || data.phone || data.email);
    }

    get showHealthSummary() {
        const data = this.reportData;
        return this.expandedSections.healthSummary && 
               !!(data.riskLevel || data.severity || data.symptoms || data.existingConditions || data.allergies || data.currentMedications);
    }

    get showCurrentVitals() {
        const data = this.reportData;
        return this.expandedSections.currentVitals && 
               !!(data.bloodPressure || data.sugarLevel || data.heartRate || data.bodyTemperature || 
                  data.oxygenSaturation || data.bmi || data.height || data.weight || data.cholesterol);
    }

    get showAIAssessment() {
        const data = this.reportData;
        return this.expandedSections.aiAssessment && 
               !!(data.aiRiskPrediction || data.aiRiskScore || data.suggestedDoctorType || data.recommendation || data.aiExplanation);
    }

    get showLifestyle() {
        const data = this.reportData;
        return this.expandedSections.lifestyle && 
               !!(data.smokingStatus || data.alcoholConsumption);
    }

    get showMedicalReports() {
        return this.expandedSections.medicalReports && 
               this.reportData.medicalReports && 
               this.reportData.medicalReports.length > 0;
    }

    get showMedicationTracking() {
        return this.expandedSections.medicationTracking && 
               this.reportData.medicationTracking && 
               this.reportData.medicationTracking.length > 0;
    }

    get medicalReportsCount() {
        return this.reportData.medicalReports ? this.reportData.medicalReports.length : 0;
    }

    get medicationTrackingCount() {
        return this.reportData.medicationTracking ? this.reportData.medicationTracking.length : 0;
    }

    
handleOpenReport() {
    console.log('Opening report for patient:', this.selectedPatientId);
    if (this.selectedPatientId) {
        this.showReportDrawer = true;
        this.loadPatientReport();
    } else {
        this.showToast('Warning', 'Please select a patient first', 'warning');
    }
}


handleCloseReport() {
    console.log('Closing report drawer');
    this.showReportDrawer = false;
}

loadPatientReport() {
    if (!this.selectedPatientId) {  
        console.warn('No patient selected');
        return;
    }
    
    this.isReportLoading = true;  
    this.reportError = null;      
    
    getPatientReport({ patientId: this.selectedPatientId })  
        .then(result => {
            console.log('Report loaded successfully:', result);
            this.reportData = result;
            this.isReportLoading = false;
            this.autoExpandSections();
        })
        .catch(error => {
            console.error('Error loading report:', error);
            this.isReportLoading = false;
            this.reportError = 'Failed to load patient report. Please try again.';
        });
}


handlePatientNameClick() {
    if (this.reportData && this.reportData.patientId) {
        const url = `/lightning/r/Patient__c/${this.reportData.patientId}/view`;
        window.open(url, '_blank');
    }
}

handlePatientIdClick() {
    if (this.reportData && this.reportData.patientId) {
        const url = `/lightning/r/Patient__c/${this.reportData.patientId}/view`;
        window.open(url, '_blank');
    }
}

handleMrnClick() {
    if (this.reportData && this.reportData.mrnNumber) {
        // Navigate to MRN record
        this.showToast('Info', 'Navigating to MRN: ' + this.reportData.mrnNumber, 'info');
    }
}

handleReportClick(event) {
    // Handle report click
    this.showToast('Info', 'Opening report details', 'info');
}
}