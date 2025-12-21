const mysql = require('mysql2/promise');
const axios = require('axios');

const dbConfig = require('../config/db');

const { KOPOKOPO_CLIENT_ID, KOPOKOPO_CLIENT_SECRET, KOPOKOPO_API_KEY, KOPOKOPO_TILL_NUMBER, KOPOKOPO_BASE_URL } = require('../config/constants');

let kopoKopoAccessToken = null;
let kopoKopoTokenExpiry = 0;

const getKopoKopoAccessToken = async () => {
    if (kopoKopoAccessToken && Date.now() < kopoKopoTokenExpiry) {
        return kopoKopoAccessToken;
    }

    try {
        const response = await axios.post(`${KOPOKOPO_BASE_URL}/oauth/token`, {
            client_id: KOPOKOPO_CLIENT_ID,
            client_secret: KOPOKOPO_CLIENT_SECRET,
            grant_type: 'client_credentials',
        }, {
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
        });

        kopoKopoAccessToken = response.data.access_token;
        kopoKopoTokenExpiry = Date.now() + (response.data.expires_in * 1000) - 60000;
        console.log('Kopo Kopo Access Token obtained.');
        return kopoKopoAccessToken;
    } catch (error) {
        console.error('Error getting Kopo Kopo Access Token:', error.response ? error.response.data : error.message);
        throw new Error('Failed to get Kopo Kopo Access Token');
    }
};

const initiateKopoKopoSTKPush = async (phoneNumber, amount, callbackUrl, clientReference) => {
    try {
        const accessToken = await getKopoKopoAccessToken();
        const response = await axios.post(`${KOPOKOPO_BASE_URL}/till_numbers/${KOPOKOPO_TILL_NUMBER}/stk_push`, {
            amount: amount,
            currency: 'KES',
            metadata: {
                client_reference: clientReference,
                payment_type: 'premium_subscription',
            },
            callback_url: callbackUrl,
            customer_phone_number: phoneNumber,
        }, {
            headers: {
                'Authorization': `Bearer ${accessToken}`,
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Api-Key': KOPOKOPO_API_KEY,
            },
        });
        console.log('Kopo Kopo STK Push initiated:', response.data);
        return response.data;
    } catch (error) {
        console.error('Error initiating Kopo Kopo STK Push:', error.response ? error.response.data : error.message);
        throw new Error('Failed to initiate STK Push');
    }
};

const processKopoKopoWebhook = async (webhookData) => {
    console.log('Kopo Kopo Webhook received:', JSON.stringify(webhookData, null, 2));

    const { status, metadata } = webhookData;
    const userId = metadata ? metadata.client_reference : null;
    const paymentType = metadata ? metadata.payment_type : null;

    if (!userId || paymentType !== 'premium_subscription') {
        console.error('Webhook: Missing userId or invalid paymentType in metadata.');
        throw new Error('Invalid webhook data.');
    }

    let connection;
    try {
        connection = await mysql.createConnection(dbConfig);

        if (status === 'success') {
            const subscriptionMonths = 1;
            const expiryDate = new Date();
            expiryDate.setMonth(expiryDate.getMonth() + subscriptionMonths);

            const sql = 'UPDATE users SET premium_until = ? WHERE id = ?';
            await connection.execute(sql, [expiryDate, userId]);
            console.log(`Webhook: User ${userId} premium_until updated to ${expiryDate}`);
        } else {
            console.log(`Webhook: Payment for user ${userId} failed or was cancelled. Status: ${status}`);
        }

        return { success: true, message: 'Webhook processed successfully.' };
    } catch (error) {
        console.error('Webhook: Error processing payment:', error);
        throw new Error('Internal server error during webhook processing.');
    } finally {
        if (connection) await connection.end();
    }
};


module.exports = {
    initiateKopoKopoSTKPush,
    processKopoKopoWebhook
};
