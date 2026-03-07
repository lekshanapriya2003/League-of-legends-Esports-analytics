# League-of-legends-Esports-analytics

A fully normalized relational database built in **MySQL 8.0** to transform raw esports match CSV data into a structured analytics-ready system.

The project models match data using 3NF normalization, enforces referential integrity with foreign keys, and provides analytical insights through views, aggregations, and stored procedures.

---

## Project Objective

Raw CSV files contained fragmented match statistics with redundancy and no relational enforcement.

This project:

* Designs a structured relational schema
* Normalizes data to Third Normal Form (3NF)
* Implements ETL using bulk ingestion
* Enables analytical queries on teams, champions, and match performance

---

## Database Architecture

### Core Entities

* `Teams`
* `Champions`
* `Matches`
* `MatchParticipants`
* `ChampionPicks`
* `TeamObjectives`

Each entity represents a real-world concept and is linked using primary and foreign keys.

---

## Schema Design (3NF)

The database is normalized to eliminate:

* Redundant team and champion names
* Update anomalies
* Inconsistent region or metadata duplication

Instead of embedding everything into one large table, entities are separated and connected through foreign keys.

Example:

```
ChampionPicks.ChampionID → Champions.ChampionID
MatchParticipants.TeamID → Teams.TeamID
```

This enforces referential integrity and prevents orphan records.

---

## ETL Pipeline

Data ingestion uses:

```sql
LOAD DATA LOCAL INFILE
```

Pipeline structure:

1. Extract → CSV files
2. Transform → Column mapping & restructuring
3. Load → Insert into normalized schema

Bulk loading ensures efficient ingestion without row-by-row inserts.

---

## Analytical Capabilities

The database supports queries such as:

* Blue vs Red side win rates
* Champion pick rate and win rate
* Team performance metrics
* Match-level total kills
* Objective control trends

Core SQL features used:

* `COUNT()`
* `SUM()`
* `AVG()`
* `GROUP BY`
* `ROUND()`
* Subqueries
* Joins

---

## Views

Views are used to abstract repeated analytical logic.

Example:

```sql
CREATE VIEW vw_side_winrates AS ...
```

Views simplify repeated queries and improve readability.

---

## Stored Procedures

Parameterized stored procedures encapsulate reusable analytics logic.

Example:

```sql
CALL sp_TeamPerformance(5);
```

This allows modular and maintainable SQL programming.

---

## Indexing & Integrity

* Primary keys on all entities
* Foreign key constraints enforced
* Indexed relationships for efficient joins
* Controlled ETL insertion to prevent duplication

---

## Example Analytics Output

| Metric                    | Insight |
| ------------------------- | ------- |
| Blue Side Win Rate        | 52.8%   |
| Highest Win Rate Champion | X       |
| Most Kills in a Match     | 47      |
| Top Performing Team       | Y       |

---

## Scalability Considerations

If scaled to millions of rows:

* Transition to star schema for OLAP efficiency
* Introduce partitioning
* Add composite indexes for heavy joins
* Migrate to analytical warehouses such as

  * Snowflake
  * Google BigQuery

---

## What This Project Demonstrates

* Relational modeling
* 3NF normalization
* Referential integrity
* Bulk ETL ingestion
* Aggregation-based analytics
* SQL modularity using views and procedures


---




