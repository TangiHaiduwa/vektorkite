const {
  CognitoIdentityProviderClient,
  AdminCreateUserCommand,
  AdminSetUserPasswordCommand,
  AdminAddUserToGroupCommand,
} = require("@aws-sdk/client-cognito-identity-provider");

const cognito = new CognitoIdentityProviderClient({});

exports.handler = async (event) => {
  const groups = event?.identity?.claims?.["cognito:groups"] || [];
  const normalizedGroups = Array.isArray(groups)
    ? groups
    : String(groups)
        .split(",")
        .map((value) => value.trim())
        .filter(Boolean);

  if (!normalizedGroups.includes("ADMIN")) {
    throw new Error("Not authorized");
  }

  const userPoolId = process.env.USER_POOL_ID;
  if (!userPoolId) {
    throw new Error("USER_POOL_ID is not configured.");
  }

  const fieldName = event?.info?.fieldName;
  const args = event?.arguments ?? {};

  if (fieldName === "adminSetUserPassword") {
    const email = args.email;
    const newPassword = args.newPassword;
    const permanent = args.permanent !== false;

    if (!email || !newPassword) {
      throw new Error("email and newPassword are required.");
    }

    const username = String(email).trim().toLowerCase();

    await cognito.send(
      new AdminSetUserPasswordCommand({
        UserPoolId: userPoolId,
        Username: username,
        Password: String(newPassword),
        Permanent: permanent,
      }),
    );

    return true;
  }

  const { email, temporaryPassword, givenName, familyName } = args;

  if (!email || !temporaryPassword) {
    throw new Error("email and temporaryPassword are required.");
  }

  const username = String(email).trim().toLowerCase();

  const userAttributes = [{ Name: "email", Value: username }];
  if (givenName) {
    userAttributes.push({ Name: "given_name", Value: String(givenName).trim() });
  }
  if (familyName) {
    userAttributes.push({ Name: "family_name", Value: String(familyName).trim() });
  }

  try {
    await cognito.send(
      new AdminCreateUserCommand({
        UserPoolId: userPoolId,
        Username: username,
        TemporaryPassword: temporaryPassword,
        MessageAction: "SUPPRESS",
        DesiredDeliveryMediums: ["EMAIL"],
        UserAttributes: userAttributes,
      }),
    );
  } catch (error) {
    if (error?.name !== "UsernameExistsException") {
      throw error;
    }
    await cognito.send(
      new AdminSetUserPasswordCommand({
        UserPoolId: userPoolId,
        Username: username,
        Password: temporaryPassword,
        Permanent: false,
      }),
    );
  }

  await cognito.send(
    new AdminAddUserToGroupCommand({
      UserPoolId: userPoolId,
      Username: username,
      GroupName: "ADMIN",
    }),
  );

  return true;
};
