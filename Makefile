.PHONY: start-dynamodb wait-dynamodb create-table test-dynamodb stop-dynamodb

# Start DynamoDB container
start-dynamodb:
	docker run -d \
		-p 8000:8000 \
		--name dynamodb-local \
		amazon/dynamodb-local:1.22.0 \
		-jar DynamoDBLocal.jar -sharedDb -inMemory

# Wait for DynamoDB to be ready
wait-dynamodb:
	@echo "Waiting for DynamoDB to be ready..."
	@for i in $$(seq 1 30); do \
		if curl -s http://localhost:8000 > /dev/null; then \
			echo "DynamoDB is ready!"; \
			exit 0; \
		fi; \
		echo "Waiting... $$i"; \
		sleep 1; \
	done; \
	echo "DynamoDB failed to start"; \
	exit 1

# Create test table
create-table:
	./wait_for_success.sh aws dynamodb create-table \
		--endpoint-url http://localhost:8000 \
		--table-name service-test-call-correlation \
		--attribute-definitions \
			AttributeName=correlationId,AttributeType=S \
			AttributeName=startUtc,AttributeType=N \
		--key-schema \
			AttributeName=correlationId,KeyType=HASH \
			AttributeName=startUtc,KeyType=RANGE \
		--region us-east-1 \
		--provisioned-throughput \
			ReadCapacityUnits=10,WriteCapacityUnits=10

# Test DynamoDB setup
test-dynamodb: start-dynamodb wait-dynamodb create-table
	@echo "Testing DynamoDB setup..."
	aws dynamodb describe-table \
		--table-name service-test-call-correlation \
		--endpoint-url http://localhost:8000

# Stop and remove DynamoDB container
stop-dynamodb:
	docker stop dynamodb-local || true
	docker rm dynamodb-local || true

# Clean start - stop existing container and start fresh
clean-start: stop-dynamodb test-dynamodb
