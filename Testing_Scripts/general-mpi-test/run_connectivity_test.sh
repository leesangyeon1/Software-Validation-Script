#!/bin/bash
#SBATCH --job-name=MPI_Connectivity_Test
#SBATCH --output=mpi_test_%j.out
#SBATCH --error=mpi_test_%j.err
#SBATCH --time=00:10:00
#SBATCH --ntasks-per-node=1
#SBATCH --mem=1G

# Load OpenMPI module
module load OpenMPI

# Set unlimited memory for nodes to test MPI
ulimit -l unlimited

# Get current date and time
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUTPUT_DIR="MPI_testing_result"
OUTPUT_FILE="${OUTPUT_DIR}/MPITest.${TIMESTAMP}"

# Create output directory if it doesn't exist
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo "Created directory: $OUTPUT_DIR"
fi

# Get system information
LINUX_VERSION=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
SLURM_VERSION=$(sinfo --version | head -1)

# Get all available compute nodes from all partitions
echo "Detecting all compute nodes in the cluster..."
ALL_NODES=$(sinfo -N -h -o "%N" | sort -u | paste -sd "," -)
TOTAL_NODE_COUNT=$(sinfo -N -h -o "%N" | sort -u | wc -l)

echo "Found $TOTAL_NODE_COUNT total nodes in cluster: $ALL_NODES"

# Get SLURM job information
JOB_ID=${SLURM_JOB_ID}
NUM_NODES=${SLURM_JOB_NUM_NODES:-$TOTAL_NODE_COUNT}
NODE_LIST=${SLURM_JOB_NODELIST:-$ALL_NODES}

# Expand node list for better readability
if [ ! -z "$SLURM_JOB_NODELIST" ]; then
    EXPANDED_NODES=$(scontrol show hostname $NODE_LIST | paste -sd "," -)
else
    EXPANDED_NODES=$ALL_NODES
fi

# Record start time
START_TIME=$(date)
START_SECONDS=$(date +%s)

# Compile MPI program
echo "Compiling MPI connectivity test program..."
mpicc -o mpi_connectivity_test mpi_connectivity_test.c

if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed!"
    exit 1
fi

# Start output file
{
    echo "=== MPI Node Connectivity Test for entire cluster ==="
    echo "Job ID: $JOB_ID"
    echo "Total nodes in cluster: $TOTAL_NODE_COUNT"
    echo "Requested nodes: $NUM_NODES"
    echo "Node range: $EXPANDED_NODES"
    echo "Actual nodes allocated: $NUM_NODES"
    echo "Node list: $NODE_LIST"
    echo ""
    echo "=== System Information ==="
    echo "Linux Version: $LINUX_VERSION"
    echo "Slurm Version: $SLURM_VERSION"
    echo ""
    echo "Start time: $START_TIME"
    echo ""
    echo "Running MPI connectivity test..."
    echo ""
} > "$OUTPUT_FILE"

# Run MPI test with all allocated nodes
mpirun -np $NUM_NODES --map-by node --mca btl ^openib ./mpi_connectivity_test >> "$OUTPUT_FILE" 2>&1

# Record end time
END_TIME=$(date)
END_SECONDS=$(date +%s)
ELAPSED=$((END_SECONDS - START_SECONDS))

# Format elapsed time
HOURS=$((ELAPSED / 3600))
MINUTES=$(((ELAPSED % 3600) / 60))
SECONDS=$((ELAPSED % 60))
FORMATTED_TIME=$(printf "%02d:%02d:%02d" $HOURS $MINUTES $SECONDS)

# Append timing information
{
    echo ""
    echo "End time: $END_TIME"
    echo "Total job time: $FORMATTED_TIME passed for the test."
} >> "$OUTPUT_FILE"

# Display results
echo ""
echo "=========================================="
echo "Test completed successfully!"
echo "=========================================="
echo "Output saved to: $OUTPUT_FILE"
echo "Total execution time: $FORMATTED_TIME"
echo ""
echo "Summary:"
cat "$OUTPUT_FILE"

# Clean up
rm -f mpi_connectivity_test

exit 0
