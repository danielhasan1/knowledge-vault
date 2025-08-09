# Isolation Levels

## TL;DR
When multiple transactions are running in a database, the isolation level determines what version/state of the data each transaction can see while others are making changes.

## 1. Definition
Isolation level is basically "I" of ACID(Atomicity, Consistency, ISOLATION, Durability). It defines how running transactions can view each other's changes

### Example:
There are two transactions, T1 and T2
T1 is trying to modify a value in Row 1. Let's say the value is 'A' and T1 wants to write 'B'
While T1 is running, T2 also wants to read Row 1. Now, how many changes made by T1 will be visible to T2 when T2 requests the same data, or Row is what isolation level decides.
Like, for example, when T2 requests the same Row 1, will it see:
- The same row
- The uncommitted value
- Will it wait till T1 commits the latest changes or not
It is determined by isolation level.

## 2. Why It Exists / Problem It Solves
In a database, thousands of transactions can be going on at once. They do request data, just like the aforementioned scenario, hence we need ways to handle how data will be visible
without enforcing isolation level
Transactions could read:
- each other's half-finished work
- Overwrite each other's changes
- As a result, return inconsistent data

## 3. Key Points
They solve the above problem and streamline how multiple transactions can interact with each other without destroying the consistency

## 4. Example
We have four isolation levels, and we will see more about them in their sections:

- READ UNCOMMITTED
- READ COMMITTED
- REPEATABLE READ
- SERIALIZABLE
