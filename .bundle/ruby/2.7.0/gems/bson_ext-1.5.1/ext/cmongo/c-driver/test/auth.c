#include "test.h"
#include "mongo.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static mongo_connection conn[1];
static const char* db = "test";

int main(){

    INIT_SOCKETS_FOR_WINDOWS;

    if (mongo_connect( conn , TEST_SERVER, 27017 )){
        printf("failed to connect\n");
        exit(1);
    }

    mongo_cmd_drop_db(conn, db);

    ASSERT(mongo_cmd_authenticate(conn, db, "user", "password") == 0);
    mongo_cmd_add_user(conn, db, "user", "password");
    ASSERT(mongo_cmd_authenticate(conn, db, "user", "password") == 1);

    mongo_cmd_drop_db(conn, db);
    mongo_destroy(conn);
    return 0;
}
