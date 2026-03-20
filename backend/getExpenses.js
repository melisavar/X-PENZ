// Scans DynamoDB expense-table and returns all expenses as JSON
// Node.js 20 — AWS SDK v3 is built into the runtime, no npm install needed
const { DynamoDBClient, ScanCommand } = require("@aws-sdk/client-dynamodb");
const { unmarshall } = require("@aws-sdk/util-dynamodb");

const client    = new DynamoDBClient({});
const TABLE_NAME = process.env.TABLE_NAME || "expense-table";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin":  "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Content-Type":                 "application/json",
};

exports.handler = async () => {
  try {
    const response = await client.send(new ScanCommand({ TableName: TABLE_NAME }));

    const expenses = (response.Items || [])
      .map(item => {
        const exp = unmarshall(item);
        return {
          ...exp,
          // DynamoDB Decimals come back as strings — convert to number for frontend .toFixed()
          amount: Number(exp.amount) || 0,
          total:  Number(exp.total)  || 0,
        };
      })
      .sort((a, b) => new Date(b.date) - new Date(a.date));

    return {
      statusCode: 200,
      headers:    CORS_HEADERS,
      body:       JSON.stringify({ expenses }),
    };

  } catch (err) {
    console.error("getExpenses error:", err);
    return {
      statusCode: 500,
      headers:    CORS_HEADERS,
      body:       JSON.stringify({ error: err.message }),
    };
  }
};
