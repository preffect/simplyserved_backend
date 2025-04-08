module.exports = {
    options: {

        // Graphile build options (default: {})
        // graphileBuildOptions: {
        //     pgOmitListSuffix: true, // Omit the "List" suffix from simple collections
        //     pgSimplifyPatch: true,          // Use "patch" instead of "userPatch" in updates
        //     pgSimplifyAllRows: true,        // Keep "allUsers" instead of simplifying to "users"
        //     pgShortPk: false,                 // Add "ById" suffix for primary key queries/mutations
        // },
        // // Connection string to the database
        // connection: process.env.DATABASE_URL || "postgres://user:password@localhost/dbname",

        // // Schemas to expose in GraphQL
        // schema: ["public"],

        // // Default GraphQL endpoint
        // graphqlRoute: "/graphql",

        // // Default GraphiQL endpoint
        // graphiqlRoute: "/graphiql",

        // // Enable GraphiQL interface (default: true in development)
        // graphiql: process.env.NODE_ENV === "development",

        // // Enable watch mode (default: true in development)
        // watchPg: process.env.NODE_ENV === "development",

        // // Enable enhanced debugging (default: false)
        // debug: false,

        // // Enable query batching (default: true)
        // enableQueryBatching: true,

        // // Disable default mutations (default: false)
        // disableDefaultMutations: false,

        // // Append plugins (default: [])
        // appendPlugins: [],

        // // Replace plugins (default: null)
        // replaceAllPlugins: null,

        // // Skip plugins (default: [])
        // skipPlugins: [],

        // // Export JSON schema for GraphQL (default: false)
        // exportJsonSchemaPath: null,

        // // Export SDL schema for GraphQL (default: false)
        // exportGqlSchemaPath: null,

        // // Enable JWT authentication
        // jwtSecret: null,

        // jwtPgTypeIdentifier: null,

        // // Default maximum rows per query
        // defaultPaginationCap: 1000,

        // // Maximum rows per query allowed
        // graphqlPaginationLimit: 1000,

        // // Disable introspection in production
        // disableGraphiqlInProduction: true,

        // // Enable Relay global IDs (default: true)
        // pgEnableRelayGlobalIds: true,

        // // Simple collections configuration
        // pgSimpleCollections: "omit",

        // // Legacy relations configuration
        // legacyRelations: "omit",

        // // Show error stack traces in GraphQL responses (default depends on NODE_ENV)
        // showErrorStack: process.env.NODE_ENV === "development",
    },
  };
  