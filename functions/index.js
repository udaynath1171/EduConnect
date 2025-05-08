const functions = require("firebase-functions");
const admin = require("firebase-admin");
const twilio = require("twilio");

admin.initializeApp();

// Twilio Credentials
const accountSid = "ACe7fa09f48846c0d773e8c9acffcf258b";
const authToken = "5bbeada8da3d31b9f50a1d7ee87a800f";
const whatsappFrom = "whatsapp:+14155238886"; // Twilio Sandbox WhatsApp number

const client = twilio(accountSid, authToken);

// Cloud Function
exports.sendAttendanceMessage = functions.firestore
  .document('attendance_records/{recordId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const parentNumber = data.parent_whatsapp_number; // Must start with +
    const studentName = data.student_name;
    const courseName = data.course_name;
    const status = data.status;

    const messageBody = `Attendance Update: ${studentName} for course ${courseName} is marked ${status}.`;

    try {
      if (parentNumber && parentNumber.startsWith('+')) {
        await client.messages.create({
          from: whatsappFrom,
          body: messageBody,
          to: "whatsapp:" + parentNumber
        });
        console.log(`✅ WhatsApp sent to ${parentNumber}`);
      } else {
        console.log('❌ No valid WhatsApp number found for parent.');
      }
    } catch (error) {
      console.error('❌ Error sending WhatsApp message:', error);
    }
});
