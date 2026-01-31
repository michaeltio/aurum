# ✨ Aurum – Project Structure Overview

This repository is organized as a **monorepo** with a clear separation of concerns between smart contracts, shared artifacts, and the frontend application 🚀.

---

## 📂 Folder Structure

### 🧠 `contract/`

Contains all **smart contract–related code** that runs on-chain ⛓️.

Includes:

* Solidity smart contracts
* Hardhat configuration
* Deployment scripts
* Tests

This folder is responsible only for **on-chain logic**. Smart contracts are compiled and deployed from here.

---

### 🔗 `shared/`

Contains **generated artifacts** that are shared between contracts and frontend 🤝.

Includes:

* Contract **ABI** files
* Deployed **contract addresses** (per network)

These files are treated as **build outputs**, not handwritten source code, and are safe to commit to the repository.

---

### 💻 `web/`

Contains the **frontend application** built with **Next.js** ⚡.

Includes:

* UI components
* Pages and layouts
* Wallet integration (Wagmi + Viem)
* Contract interactions using ABI and addresses from `shared/`

This folder handles all **user-facing logic**.

---

### 🛠️ `scripts/`

Contains utility scripts used for development workflows 🤖.

Includes:

* Scripts to **sync ABI and contract addresses** from compiled/deployed contracts into `shared/`

These scripts ensure the frontend always stays in sync with the latest contract state without manual copying.

---

## 📝 Summary

* 🧠 `contract/` → on-chain logic (Solidity)
* 🔗 `shared/` → ABI & addresses (generated artifacts)
* 💻 `web/` → frontend (Next.js)
* 🛠️ `scripts/` → automation (sync & tooling)

Each folder contains its own detailed README for deeper explanation.
