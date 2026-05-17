#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MAX_HOSTNAME 256
#define MSG_SIZE 100

int main(int argc, char** argv) {
    int rank, size, len;
    char hostname[MAX_HOSTNAME];
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Get_processor_name(processor_name, &len);
    
    gethostname(hostname, MAX_HOSTNAME);
    
    // Print header on rank 0
    if (rank == 0) {
        printf("========================================\n");
        printf("MPI Node Connectivity Test\n");
        printf("========================================\n");
        printf("Total processes: %d\n", size);
        
        char* job_id = getenv("SLURM_JOB_ID");
        char* num_nodes = getenv("SLURM_JOB_NUM_NODES");
        char* num_tasks = getenv("SLURM_NTASKS");
        char* nodelist = getenv("SLURM_JOB_NODELIST");
        
        if (job_id) printf("SLURM Job ID: %s\n", job_id);
        if (num_nodes) printf("SLURM Nodes: %s\n", num_nodes);
        if (num_tasks) printf("SLURM Tasks: %s\n", num_tasks);
        if (nodelist) printf("Node List: %s\n", nodelist);
        printf("========================================\n");
        fflush(stdout);
    }
    
    MPI_Barrier(MPI_COMM_WORLD);
    
    // Each process prints its hostname
    printf("Process %d of %d running on %s\n", rank, size, hostname);
    fflush(stdout);
    
    MPI_Barrier(MPI_COMM_WORLD);
    
    if (rank == 0) {
        printf("\nStarting connectivity tests between all nodes...\n");
        fflush(stdout);
    }
    
    MPI_Barrier(MPI_COMM_WORLD);
    
    // Connectivity test: each process sends to all others
    int *send_data = (int*)malloc(size * sizeof(int));
    int *recv_data = (int*)malloc(size * sizeof(int));
    int *failed_connections = (int*)calloc(size * size, sizeof(int));
    
    for (int i = 0; i < size; i++) {
        send_data[i] = rank;
    }
    
    // All-to-all communication
    MPI_Alltoall(send_data, 1, MPI_INT, recv_data, 1, MPI_INT, MPI_COMM_WORLD);
    
    // Verify received data
    int local_failures = 0;
    for (int i = 0; i < size; i++) {
        if (recv_data[i] != i) {
            failed_connections[rank * size + i] = 1;
            local_failures++;
        }
    }
    
    // Gather all failure information to rank 0
    int *all_failures = NULL;
    if (rank == 0) {
        all_failures = (int*)malloc(size * size * sizeof(int));
    }
    
    MPI_Gather(failed_connections, size, MPI_INT, all_failures, size, MPI_INT, 0, MPI_COMM_WORLD);
    
    // Collect all hostnames
    char *all_hostnames = NULL;
    if (rank == 0) {
        all_hostnames = (char*)malloc(size * MAX_HOSTNAME * sizeof(char));
    }
    
    MPI_Gather(hostname, MAX_HOSTNAME, MPI_CHAR, all_hostnames, MAX_HOSTNAME, MPI_CHAR, 0, MPI_COMM_WORLD);
    
    MPI_Barrier(MPI_COMM_WORLD);
    
    // Print results on rank 0
    if (rank == 0) {
        printf("\n========================================\n");
        printf("NODE CONNECTIVITY TEST RESULTS\n");
        printf("========================================\n");
        
        int total_failures = 0;
        for (int i = 0; i < size * size; i++) {
            if (all_failures[i]) total_failures++;
        }
        
        if (total_failures == 0) {
            // Extract node numbers for range display
            char first_node[MAX_HOSTNAME], last_node[MAX_HOSTNAME];
            strncpy(first_node, all_hostnames, MAX_HOSTNAME);
            strncpy(last_node, all_hostnames + (size - 1) * MAX_HOSTNAME, MAX_HOSTNAME);
            
            // Extract node numbers
            char *first_num = strstr(first_node, "node-");
            char *last_num = strstr(last_node, "node-");
            
            if (first_num && last_num) {
                first_num += 5; // Skip "node-"
                last_num += 5;
                char *first_dot = strchr(first_num, '.');
                char *last_dot = strchr(last_num, '.');
                if (first_dot) *first_dot = '\0';
                if (last_dot) *last_dot = '\0';
                
                printf("Node %s~%s passed the connection test\n", first_num, last_num);
            }
            
            printf("From %s to %s is connected and able to communicate with each other.\n", 
                   first_node, last_node);
            printf("\nConnectivity test completed\n");
            printf("========================================\n");
            printf("✓ Connectivity test COMPLETED\n");
        } else {
            printf("WARNING: Connection failures detected!\n\n");
            
            // Find which nodes failed
            int *failed_nodes = (int*)calloc(size, sizeof(int));
            for (int i = 0; i < size; i++) {
                for (int j = 0; j < size; j++) {
                    if (all_failures[i * size + j]) {
                        failed_nodes[i] = 1;
                        failed_nodes[j] = 1;
                    }
                }
            }
            
            printf("Connectivity test done. The following nodes are not able to communicate:\n");
            for (int i = 0; i < size; i++) {
                if (failed_nodes[i]) {
                    char node[MAX_HOSTNAME];
                    strncpy(node, all_hostnames + i * MAX_HOSTNAME, MAX_HOSTNAME);
                    char *node_name = strstr(node, "node-");
                    char *dot = strchr(node, '.');
                    if (node_name && dot) {
                        *dot = '\0';
                        printf("  - %s(%s)\n", node_name, all_hostnames + i * MAX_HOSTNAME);
                    }
                }
            }
            printf("========================================\n");
            
            free(failed_nodes);
        }
        
        free(all_failures);
        free(all_hostnames);
    }
    
    free(send_data);
    free(recv_data);
    free(failed_connections);
    
    MPI_Finalize();
    return 0;
}
