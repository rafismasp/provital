# ERP - Provital
> Enterprise Resource Planning (Provital) [_here_](https:/erp.tri-saudara.com). <!-- If you have the project hosted somewhere, include the link here. -->

## Table of Contents
* [General Info](#general-information)
* [Technologies Used](#technologies-used)
* [Features](#features)
* [Screenshots](#screenshots)
* [Setup](#setup)
* [Usage](#usage)
* [Project Status](#project-status)
* [Contact](#contact)
<!-- * [License](#license) -->


## General Information
- This software includes a warehouse inventory module, HR module, finance module, sales module, Batch Numbering Module, invoicing module for healthcare industries (PT. Provital Perdana).
<!-- You don't have to answer all the questions - just the ones relevant to your project. -->


## Technologies Used
- ![Ruby](https://img.shields.io/badge/Ruby-2.7.0-blue)
- ![Rails](https://img.shields.io/badge/Rails-5.2.3-blue)
- ![UIKit](https://img.shields.io/badge/UIKit-3.5.3-blue)
- ![JQuery](https://img.shields.io/badge/JQuery-1.12.4-blue)
- ![ChartJS](https://img.shields.io/badge/ChartJS-2.8.0-blue)
- ![MariaDB](https://img.shields.io/badge/MariaDB-10.3.27-blue)
- ![Nginx](https://img.shields.io/badge/Nginx-1.6.2-blue)

## Features
List the ready features here:

<details>
<summary> Warehouse </summary>
 
- Inventory
- Stock IN
	- FG Receiving Notes
	- Sterilization Product Receipt Notes
	- Good Receipt Notes
	- Material Return
	- Semi FG Receiving Notes
	- Virtual Receipt Notes
	- General Receipt Notes
	- Product Receipt Notes
	- Consumable Receipt Notes
	- Equipment Receipt Notes
- Stock Out
	- Material Issue
	- Semi FG for Sterilization
	- Material Additional
- Adjustment Tools
- Reports
	- Material Receiving Form
- Direct Labor
	- Daftar Borongan
	- Daftar Harga
	- Laporan

</details>

<details>
<summary> Delivery </summary>

- Picking Slip
- Outgoing Inspection
- Delivery Orders
- Vehicle Inspections
- Material Delivery Notes

</details>

<details>
<summary> QC </summary>

- Material Check Sheets
- Rejected Material

</details>

<details>
<summary> PPIC </summary>

- SFO Production
- SFO Sterilization
- Reports
	- SFO Outstanding
	- Monitoring Kanban

</details>

<details>
<summary> Sales & Marketing </summary>

- Company Profile
- Sales Orders
- Customer
- Production Orders (SPP)

</details>

<details>
<summary> Purchasing </summary>

- Supplier
- Purchase Request Form (PRF)
- PDM
- Purchase Order
- Reports
	- Outstanding PDM
	- Outstanding PRF
	- Outstanding PO Supplier

</details>

<details>
<summary> Code Numbering </summary>

- Product
- Material
- General
- Consumable
- Equipment
- Bill of Materials
- Product Risk Categories
- Product Categories
- Product Sub Categories
- Product Type
- Colors
- Unit

</details>

<details>
<summary> Human Resource </summary>

- Position
- Section
- Employee Contracts
- Internship Contracts
- Employees
- Employee Attendances
	- List of Schedule
	- Employee Schedule
	- Employee Overtimes
	- Employee Presences
	- Employee Working Hour
- Internship
- Department
- Employee Absences
- Department Hierarchies
- Employee Leaves
- Master File

</details>

<details>
<summary> Finance </summary>

- Account Payable (AP)
	-	Invoice Receipt
	- Invoice Supplier
	- Payment Request
	- Payment Suppliers
	- Faktur Pajak Masukan
	- Template Banks
	- Rangkuman AP
	- Rekap AP (Hutang & Pembayaran)
- Account Receivable (AR)
	-	Invoice Customer
	- Invoice Customer Price Logs
	- Payment Received
	- Faktur Pajak Keluaran
	- Proforma Invoice Customer
	- Rangkuman AR
- Cost Project Finance
- Kurs Pajak
- Metode Pembayaran
- Keuangan
	- Biaya Rutin
	- BPK Biaya Rutin
	- Bukti Pengeluaran Kas
	- Pengajuan Kasbon
	- Open Print BPK Rutin
	- Open Print BPK
	- Voucher Payment
	- Voucher Payment Receive
- Master
	- List Internal Bank
	- List External Bank
- Tools
	- Invoice Tools

</details>

<details>
<summary> Tools </summary>

- User Accounts
- User Permissions
- Job List
- To-Do List
- Meeting Minutes

</details>

## Screenshots
![image](https://drive.google.com/uc?export=view&id=1OUF7AsPNPBB-cOeGPiox7Z1toBSX93dv)
<!-- If you have screenshots you'd like to share, include them here. -->


## Setup
How to setup, please run:
`bundle install`
and
`rake assets:precompile RAILS_ENV=production`


## Usage
running in production, please run:
`sh production_run.sh start`
and to stop it, please run:
`sh production_run.sh start`


## Project Status
Project is: _in progress_


## Contact
Created by [@vzveda](https://adenpribadi.github.io/) - feel free to contact me!


<!-- Optional -->
<!-- ## License -->
<!-- This project is open source and available under the [... License](). -->

<!-- You don't have to include all sections - just the one's relevant to your project -->
