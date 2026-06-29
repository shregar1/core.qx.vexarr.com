#!/usr/bin/env bash
# qx Broker gRPC — grpcurl cheat-sheet (generated).
# Requires: grpcurl (https://github.com/fullstorydev/grpcurl).
# No server reflection on qx → always pass the proto with -import-path/-proto.
set -euo pipefail

PROTO_DIR="$(cd "$(dirname "$0")" && pwd)"
ADDR="${QX_GRPC_ADDR:-localhost:50051}"      # host:port
TOKEN="${QX_TOKEN:-REPLACE_ME}"               # keyx API key or local token
AUTH=(-H "authorization: Bearer ${TOKEN}")
PROTO=(-import-path "$PROTO_DIR" -proto qx.proto)
# For a TLS endpoint drop -plaintext; for local dev keep it.
PLAINTEXT="-plaintext"

# List the 34 methods on qx.v1.Broker:
grpcurl "${PROTO[@]}" $PLAINTEXT "$ADDR" list qx.v1.Broker || true

# ───────── Topics & Messaging ─────────
# OpenTopic: Create/open a topic with N partitions (idempotent).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"name": "orders", "partition_count": 6}' "$ADDR" qx.v1.Broker/OpenTopic

# Send: Append one record. `key`/`payload` are base64-encoded bytes.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "key": "dXNlci00Mg==", "payload": "eyJvcmRlcl9pZCI6IDEwMDEsICJhbW91bnQiOiA0OTk5fQ=="}' "$ADDR" qx.v1.Broker/Send

# SendBatch: Append many records in one round-trip.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "items": [{"key": "dXNlci00Mg==", "payload": "eyJvcmRlcl9pZCI6IDEwMDEsICJhbW91bnQiOiA0OTk5fQ=="}, {"key": "dXNlci00Mw==", "payload": "eyJvcmRlcl9pZCI6MTAwMn0="}]}' "$ADDR" qx.v1.Broker/SendBatch

# Receive: Pull up to `max` messages (lease/visibility semantics).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "max": 10}' "$ADDR" qx.v1.Broker/Receive

# ReceiveStream: SERVER-STREAMING: long-poll a continuous stream of messages. In Postman click Invoke and watch the stream pane; Ctrl-C to stop in grpcurl.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "max_batch": 50, "poll_interval_ms": 250}' "$ADDR" qx.v1.Broker/ReceiveStream   # SERVER-STREAMING (stays open)

# Ack: Acknowledge a message by its receipt (removes from inflight).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "receipt": {"partition": 0, "record_id": 1, "attempt": 1}}' "$ADDR" qx.v1.Broker/Ack

# Nack: Negative-ack: requeue the message for redelivery.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "receipt": {"partition": 0, "record_id": 1, "attempt": 1}}' "$ADDR" qx.v1.Broker/Nack

# ExtendVisibility: Extend the visibility timeout of an inflight message.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "receipt": {"partition": 0, "record_id": 1, "attempt": 1}, "extension_ms": 30000}' "$ADDR" qx.v1.Broker/ExtendVisibility

# Stats: Per-topic queue depths.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders"}' "$ADDR" qx.v1.Broker/Stats

# ───────── Consumer Groups ─────────
# StreamFromGroup: Read from a partition starting at the group's committed offset.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "group": "billing-workers", "partition": 0, "max": 100}' "$ADDR" qx.v1.Broker/StreamFromGroup

# CommitGroupOffset: Commit a consumed offset for (group, partition).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "group": "billing-workers", "partition": 0, "offset": 42}' "$ADDR" qx.v1.Broker/CommitGroupOffset

# GetGroupOffset: Read the committed offset for (group, partition).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "group": "billing-workers", "partition": 0}' "$ADDR" qx.v1.Broker/GetGroupOffset

# ───────── Group Coordinator ─────────
# JoinGroup: Join a rebalanceable group; returns your member id + partition assignment.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "group": "billing-workers"}' "$ADDR" qx.v1.Broker/JoinGroup

# Heartbeat: Keep membership alive; surfaces rebalances via a new generation.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "group": "billing-workers", "member_id": 1}' "$ADDR" qx.v1.Broker/Heartbeat

# LeaveGroup: Leave the group (triggers a rebalance).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "group": "billing-workers", "member_id": 1}' "$ADDR" qx.v1.Broker/LeaveGroup

# StreamForMember: Read records for this member's assigned partitions.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"topic": "orders", "group": "billing-workers", "member_id": 1, "max": 100}' "$ADDR" qx.v1.Broker/StreamForMember

# ───────── Workflow Tasks ─────────
# CreateRootTask: Start a workflow DAG with a root task.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"workflow": "order-fulfillment", "payload": "eyJvcmRlcl9pZCI6IDEwMDEsICJhbW91bnQiOiA0OTk5fQ=="}' "$ADDR" qx.v1.Broker/CreateRootTask

# CreateChildTask: Add a child task under a parent.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"workflow": "order-fulfillment", "parent_id": 1, "payload": "eyJzdGVwIjoicmVzZXJ2ZS1pbnZlbnRvcnkifQ=="}' "$ADDR" qx.v1.Broker/CreateChildTask

# GetTask: Fetch a task (status: 0=Pending 1=Running 2=Done 3=Failed 4=Cancelled).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"workflow": "order-fulfillment", "task_id": 1}' "$ADDR" qx.v1.Broker/GetTask

# ListChildren: List child task ids of a parent.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"workflow": "order-fulfillment", "parent_id": 1}' "$ADDR" qx.v1.Broker/ListChildren

# MarkTaskRunning: Transition a task to Running.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"workflow": "order-fulfillment", "task_id": 1}' "$ADDR" qx.v1.Broker/MarkTaskRunning

# CompleteTask: Mark a task Done with a result payload (base64 bytes).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"workflow": "order-fulfillment", "task_id": 1, "result": "eyJzdGF0dXMiOiAib2siLCAic2hpcHBlZCI6IHRydWV9"}' "$ADDR" qx.v1.Broker/CompleteTask

# FailTask: Mark a task Failed with an error string.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"workflow": "order-fulfillment", "task_id": 1, "error": "payment declined"}' "$ADDR" qx.v1.Broker/FailTask

# CancelTask: Cancel a task (and its subtree).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"workflow": "order-fulfillment", "task_id": 1}' "$ADDR" qx.v1.Broker/CancelTask

# CompleteTaskWithEmits: Complete a task and atomically stage topic emits (transactional outbox).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"workflow": "order-fulfillment", "task_id": 1, "result": "eyJzdGF0dXMiOiAib2siLCAic2hpcHBlZCI6IHRydWV9", "emits": [{"topic": "shipments", "payload": "eyJvcmRlcl9pZCI6MTAwMX0="}]}' "$ADDR" qx.v1.Broker/CompleteTaskWithEmits

# ───────── Schema Registry ─────────
# RegisterSchema: Register a schema for a subject (returns assigned id + version).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"subject": "orders-value", "bytes": "eyJ0eXBlIjogInJlY29yZCIsICJuYW1lIjogIk9yZGVyIiwgImZpZWxkcyI6IFt7Im5hbWUiOiAib3JkZXJfaWQiLCAidHlwZSI6ICJsb25nIn0sIHsibmFtZSI6ICJhbW91bnQiLCAidHlwZSI6ICJpbnQifV19"}' "$ADDR" qx.v1.Broker/RegisterSchema

# GetSchemaById: Fetch a schema by its global id.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"id": 1}' "$ADDR" qx.v1.Broker/GetSchemaById

# GetSchemaVersion: Fetch a specific (subject, version).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"subject": "orders-value", "version": 1}' "$ADDR" qx.v1.Broker/GetSchemaVersion

# GetLatestSchema: Fetch the latest version for a subject.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"subject": "orders-value"}' "$ADDR" qx.v1.Broker/GetLatestSchema

# ListSchemaVersions: List all versions registered for a subject.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"subject": "orders-value"}' "$ADDR" qx.v1.Broker/ListSchemaVersions

# ListSubjects: List all registered subjects. (empty request message)
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{}' "$ADDR" qx.v1.Broker/ListSubjects

# ───────── Triggers ─────────
# RegisterTrigger: Durably bind a topic to a workflow (0 = use server defaults).
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"name": "orders->fulfillment", "topic": "orders", "workflow": "order-fulfillment", "batch_size": 0, "poll_interval_ms": 0}' "$ADDR" qx.v1.Broker/RegisterTrigger

# UnregisterTrigger: Remove a trigger by name.
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{"name": "orders->fulfillment"}' "$ADDR" qx.v1.Broker/UnregisterTrigger

# ListTriggers: List all registered triggers. (empty request message)
grpcurl "${PROTO[@]}" $PLAINTEXT "${AUTH[@]}" \
  -d '{}' "$ADDR" qx.v1.Broker/ListTriggers
