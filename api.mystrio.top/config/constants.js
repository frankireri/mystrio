const JWT_SECRET = process.env.JWT_SECRET;
const saltRounds = 10;

const KOPOKOPO_CLIENT_ID = process.env.KOPOKOPO_CLIENT_ID;
const KOPOKOPO_CLIENT_SECRET = process.env.KOPOKOPO_CLIENT_SECRET;
const KOPOKOPO_API_KEY = process.env.KOPOKOPO_API_KEY;
const KOPOKOPO_TILL_NUMBER = process.env.KOPOKOPO_TILL_NUMBER;
const KOPOKOPO_BASE_URL = 'https://sandbox.kopokopo.com/api/v1';

module.exports = {
    JWT_SECRET,
    saltRounds,
    KOPOKOPO_CLIENT_ID,
    KOPOKOPO_CLIENT_SECRET,
    KOPOKOPO_API_KEY,
    KOPOKOPO_TILL_NUMBER,
    KOPOKOPO_BASE_URL
};
