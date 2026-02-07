# Migration Plan: React to Flutter

## Overview
Migrate React web app (Ethernet-CRM-pr-executive-management) to Flutter app (madhuram_app) with 100% feature parity.

## Component Inventory

### React App Components
| Component | Path | Status in Flutter |
|-----------|------|-------------------|
| Login | pages/Login.jsx | Exists (login_page.dart) |
| ProjectSelection | pages/ProjectSelection.jsx | Exists (project_selection_page.dart) |
| Dashboard | pages/Dashboard.jsx | Exists (dashboard_page.dart) |
| Materials | pages/Materials.jsx | Exists (materials_page.dart) |
| StockAreas | pages/StockAreas.jsx | Exists (stock_areas_page.dart) |
| PurchaseRequests | pages/PurchaseRequests.jsx | Exists (purchase_requests_page.dart) |
| PurchaseOrders | pages/PurchaseOrders.jsx | Exists (purchase_orders_page_full.dart) |
| PurchaseOrdersPreview | pages/PurchaseOrdersPreview.jsx | Missing |
| StockTransfers | pages/StockTransfers.jsx | Exists (stock_transfers_page.dart) |
| Consumption | pages/Consumption.jsx | Exists (consumption_page.dart) |
| Returns | pages/Returns.jsx | Exists (returns_page.dart) |
| Vendors | pages/Vendors.jsx | Exists (vendors_page_full.dart) |
| Reports | pages/Reports.jsx | Exists (reports_page.dart) |
| AuditLogs | pages/AuditLogs.jsx | Exists (audit_logs_page.dart) |
| Projects | pages/Projects.jsx | Exists (projects_page.dart) |
| BOQ | pages/BOQ.jsx | Exists (boq_page.dart) |
| MAS | pages/MAS.jsx | Exists (mas_page.dart) - Different concept |
| Samples | pages/Samples.jsx | Exists (samples_page.dart) - Different concept |
| VendorComparison | pages/VendorComparison.jsx | Exists (vendor_comparison_page.dart) |
| Challans | pages/Challans.jsx | Exists (challans_page.dart) |
| MER | pages/MER.jsx | Exists (mer_page.dart) |
| MIR | pages/MIR.jsx | Exists (mir_page_full.dart) |
| MIRPreview | pages/MIRPreview.jsx | Missing |
| ITR | pages/ITR.jsx | Exists (itr_page_full.dart) |
| ITRPreview | pages/ITRPreview.jsx | Missing |
| Billing | pages/Billing.jsx | Exists (billing_page.dart) |
| Documents | pages/Documents.jsx | Exists (documents_page.dart) |
| Users | pages/Users.jsx | Merged into profile_page.dart |
| Profile | pages/Profile.jsx | Exists (profile_page.dart) |

## Gap Analysis

| Feature | React Status | Flutter Status | Priority | Complexity |
|---------|-------------|----------------|----------|------------|
| Login | Complete | Complete - missing Devang demo, TOS links | High | Low |
| Project Selection | Complete with PDF upload | Basic - missing PDF extraction | High | Medium |
| Dashboard | Complete | Complete - needs timeline activity | Medium | Low |
| BOQ CRUD | Full CRUD | Create only - missing Edit/Delete | High | Medium |
| PO Upload & Extract | Complete with PDF/Excel | Missing entirely | High | High |
| PO Manual Entry | Complete form | Missing | High | High |
| PO Preview | Complete editable preview | Missing | High | High |
| MIR Upload & Entry | Complete | Missing | High | High |
| MIR Preview | Complete editable preview | Missing | High | High |
| ITR Upload & Entry | Complete | Missing | High | High |
| ITR Preview | Complete editable preview | Missing | High | High |
| Users CRUD | Full CRUD | Add only - missing Edit/Delete/Role | High | Medium |
| Vendors CRUD | Full CRUD | Add only - missing Edit/Delete | High | Medium |
| Materials CRUD | Full CRUD | Add only - missing Edit/Delete/Price | High | Medium |
| Purchase Requests | 3-step wizard | Basic dialog | Medium | High |
| Stock Transfers | 3-step wizard | Basic dialog | Medium | High |
| Reports | 4 tabs, charts, date range | Single view, basic | Medium | High |
| MAS | Approval workflow | Material abstract (wrong concept) | Medium | High |
| Samples | PDF extraction, floor config | Basic tracking | Medium | High |
| Stock Areas | Hierarchical warehouse/zone/rack | Flat list | Medium | Medium |
| Returns | Inspection workflow | Simple list | Medium | Medium |
| Audit Logs | Entity/action tracking | Status-based | Low | Medium |
| MER | Client acknowledgment | Simple verification | Low | Medium |
| Challans CRUD | Verify/status tracking | List only - missing actions | Medium | Low |
| Billing CRUD | Invoice generation | List only - missing actions | Medium | Low |
| Documents CRUD | Upload/download | List only - missing actions | Low | Low |
| Consumption CRUD | Chart + logging | List only - missing chart | Medium | Medium |
| Vendor Comparison | Comparison matrix | Basic comparison | Low | Medium |

## Implementation Priority
1. Infrastructure (API client, auth, navigation)
2. Core CRUD (BOQ, Users, Vendors, Materials, PO, MIR, ITR)
3. Upload/Extract (PO, MIR, ITR, Purchase Requests)
4. Conceptual fixes (MAS, Samples, Stock Areas, Returns)
5. Charts & Reports
6. Projects & Vendor Comparison
7. Polish & Edge Cases
