FROM openlink/virtuoso-opensource-7:latest

# Your memory tuning
ENV VIRT_Parameters_NumberOfBuffers=400000 \
    VIRT_Parameters_MaxDirtyBuffers=300000 \
    VIRT_Parameters_MaxCheckpointRemap=100000

# Pre-seed the fully configured database (includes VADs, user, LDP folder)
COPY preconfigured-db /database

EXPOSE 8890 1111

#HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
#  CMD curl -f http://localhost:8890/about/ || exit 1
