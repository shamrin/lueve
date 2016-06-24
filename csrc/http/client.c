#include <runtime.h>
#include <unix/unix.h>
#include <http/http.h>


typedef struct client {

} *client;


static void http_input(buffer b, thunk)
{
}


// also query
void http_request(table headers, buffer body, buffer_handler respose)
{
    
}


{client open_http_client(station s, table headers, buffer body, buffer_handler respose)
{
    void tcp_create_client (heap h,
                        table addr,
                        buffer_handler each,
                            thunk connected);
}

