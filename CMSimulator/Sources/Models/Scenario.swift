//
//  Scenario.swift
//  CMSimulator
//
//  Phase 5: what makes this a decision-making simulator rather than one
//  game about buildings.
//
//  Every scenario runs on the same machine - convert cash and people and
//  time into finished units, under a clock, against uncertain supply and
//  an uncertain buyer. What actually differs between a building site and
//  a startup is the *vocabulary*, the work streams, the incident deck and
//  the numbers. All four live here, so a new scenario is data rather than
//  a new engine.
//
//  The structural buckets are deliberately shared. There are always five
//  classes of thing that can go wrong and six capability levers; a
//  scenario renames and re-flavours them rather than inventing its own,
//  which is what keeps a single leaderboard metric (profit) meaningful
//  across all of them.
//

import Foundation

// MARK: - Scenario

enum ScenarioKind: String, CaseIterable, Identifiable, Codable {
    case construction
    case startup
    case importing

    var id: String { rawValue }

    var name: String {
        switch self {
        case .construction: return String(localized: "Construction", comment: "Scenario name")
        case .startup: return String(localized: "Startup", comment: "Scenario name")
        case .importing: return String(localized: "Import & resale", comment: "Scenario name")
        }
    }

    var tagline: String {
        switch self {
        case .construction:
            return String(localized: "Deliver a building for a fixed price, against a fixed date.", comment: "Scenario tagline")
        case .startup:
            return String(localized: "Launch a product, grow real customers, and sell the company for what it is worth.", comment: "Scenario tagline")
        case .importing:
            return String(localized: "Buy goods abroad, sell them on a marketplace, and find out where the margin really goes.", comment: "Scenario tagline")
        }
    }

    var symbolName: String {
        switch self {
        case .construction: return "building.2.fill"
        case .startup: return "laptopcomputer"
        case .importing: return "shippingbox.fill"
        }
    }

    /// What this scenario teaches that the other one does not - shown on
    /// the picker so the choice is legible before committing an hour.
    var signature: String {
        switch self {
        case .construction:
            return String(localized: "Materials arrive late and idle crews still get paid. Supply timing is the whole game.", comment: "Scenario signature lesson")
        case .startup:
            return String(localized: "Launching early compounds. Every day you polish before launch is growth you never get back.", comment: "Scenario signature lesson")
        case .importing:
            return String(localized: "You can sell every unit at a profit and still miss payroll, because the money is on a ship.", comment: "Scenario signature lesson")
        }
    }

    // MARK: Vocabulary
    //
    // The engine's concepts do not change; only what the player calls
    // them. Keeping these in one place is what stops "site" and "crew"
    // leaking into a scenario where neither word means anything.

    /// The board tab showing work streams.
    var boardName: String {
        switch self {
        case .construction: return String(localized: "Site", comment: "Board tab: work streams")
        case .startup: return String(localized: "Product", comment: "Board tab: work streams")
        case .importing: return String(localized: "Operation", comment: "Board tab: work streams")
        }
    }

    /// The people you hire.
    var staffName: String {
        switch self {
        case .construction: return String(localized: "Crew", comment: "Collective noun for hired staff")
        case .startup: return String(localized: "Team", comment: "Collective noun for hired staff")
        case .importing: return String(localized: "Team", comment: "Collective noun for hired staff")
        }
    }

    /// The consumable that work is built out of.
    var supplyName: String {
        switch self {
        case .construction: return String(localized: "Materials", comment: "Consumable resource name")
        case .startup: return String(localized: "Growth", comment: "Consumable resource name")
        case .importing: return String(localized: "Stock", comment: "Consumable resource name")
        }
    }

    /// The verb on the button that buys more of it.
    var supplyOrderVerb: String {
        switch self {
        case .construction: return String(localized: "Order", comment: "Button: buy more of the consumable")
        case .startup: return String(localized: "Promote", comment: "Button: buy more of the consumable")
        case .importing: return String(localized: "Buy stock", comment: "Button: buy more of the consumable")
        }
    }

    /// Who pays you.
    var counterpartyName: String {
        switch self {
        case .construction: return String(localized: "Client", comment: "Who pays the player")
        case .startup: return String(localized: "Investors", comment: "Who pays the player")
        case .importing: return String(localized: "Buyers", comment: "Who pays the player")
        }
    }

    /// The thing hidden inside finished work that comes due at the end.
    var debtName: String {
        switch self {
        case .construction: return String(localized: "Defects", comment: "Hidden quality debt")
        case .startup: return String(localized: "Tech debt", comment: "Hidden quality debt")
        case .importing: return String(localized: "Returns", comment: "Hidden quality debt")
        }
    }

    /// The end of the run.
    var handoverName: String {
        switch self {
        case .construction: return String(localized: "Handover", comment: "End of the run")
        case .startup: return String(localized: "Exit", comment: "End of the run")
        case .importing: return String(localized: "Season close", comment: "End of the run")
        }
    }

    /// What the daily cost of overrunning is called.
    var overrunName: String {
        switch self {
        case .construction: return String(localized: "Late penalties", comment: "Cost of running past the deadline")
        case .startup: return String(localized: "Bridge financing", comment: "Cost of running past the deadline")
        case .importing: return String(localized: "Overrun", comment: "Cost of running past the deadline")
        }
    }

    /// Whether this scenario buys a physical, lead-timed supply at all.
    var hasSupplyChain: Bool {
        switch self {
        case .construction: return true
        case .startup: return false
        case .importing: return true
        }
    }

    var suppliersName: String {
        switch self {
        case .construction: return String(localized: "Who supplies it", comment: "Order sheet: suppliers section")
        case .startup: return String(localized: "Who provides it", comment: "Order sheet: suppliers section")
        case .importing: return String(localized: "Which supplier", comment: "Order sheet: suppliers section")
        }
    }
}

// MARK: - Capability naming

extension CapabilityKind {
    /// The six levers are structurally identical across scenarios - each
    /// still answers its own question - but a startup does not have a
    /// procurement department and a building site does not have a
    /// roadmap.
    func displayName(in scenario: ScenarioKind) -> String {
        switch (self, scenario) {
        case (.planning, .construction):       return String(localized: "Planning", comment: "Capability name")
        case (.planning, .startup):            return String(localized: "Roadmap", comment: "Capability name")
        case (.planning, .importing):          return String(localized: "Demand planning", comment: "Capability name")
        case (.procurement, .construction):    return String(localized: "Acquisitions", comment: "Capability name")
        case (.procurement, .startup):         return String(localized: "Go-to-market", comment: "Capability name")
        case (.procurement, .importing):       return String(localized: "Sourcing", comment: "Capability name")
        case (.quality, .construction):        return String(localized: "Quality", comment: "Capability name")
        case (.quality, .startup):             return String(localized: "Engineering quality", comment: "Capability name")
        case (.quality, .importing):           return String(localized: "Inspection", comment: "Capability name")
        case (.risk, .construction):           return String(localized: "Risk", comment: "Capability name")
        case (.risk, .startup):                return String(localized: "Resilience", comment: "Capability name")
        case (.risk, .importing):              return String(localized: "Trade compliance", comment: "Capability name")
        case (.communications, .construction): return String(localized: "Communications", comment: "Capability name")
        case (.communications, .startup):      return String(localized: "Investor relations", comment: "Capability name")
        case (.communications, .importing):    return String(localized: "Buyer relations", comment: "Capability name")
        case (.training, .construction):       return String(localized: "Training", comment: "Capability name")
        case (.training, .startup):            return String(localized: "Learning & development", comment: "Capability name")
        case (.training, .importing):          return String(localized: "Team development", comment: "Capability name")
        }
    }

    func summary(in scenario: ScenarioKind) -> String {
        switch (self, scenario) {
        case (.planning, .construction):
            return String(localized: "Forecasts the finish date and warns you about trouble before it lands. Higher levels let you fast-track a package early.", comment: "Capability summary")
        case (.planning, .startup):
            return String(localized: "Forecasts the ship date and flags risks before they bite. Higher levels let you start a workstream before its dependency is done.", comment: "Capability summary")
        case (.planning, .importing):
            return String(localized: "Sharpens your read of the season - when demand peaks and how big it gets. Without it you are buying stock on a guess.", comment: "Capability summary")
        case (.procurement, .construction):
            return String(localized: "Cuts delivery lead times and unlocks price hedging, so crews stop standing idle waiting on materials.", comment: "Capability summary")
        case (.procurement, .startup):
            return String(localized: "Sharpens go-to-market. Lowers what each new customer costs to acquire and keeps the channel working as you scale.", comment: "Capability summary")
        case (.procurement, .importing):
            return String(localized: "Better factory terms and faster shipping. Lower landed cost and a shorter wait between paying and selling.", comment: "Capability summary")
        case (.quality, .construction):
            return String(localized: "Inspects work in progress. Defects caught now cost a fraction of what they cost at handover.", comment: "Capability summary")
        case (.quality, .startup):
            return String(localized: "Reviews and tests as you go. Tech debt paid down now costs a fraction of what it costs at due diligence.", comment: "Capability summary")
        case (.quality, .importing):
            return String(localized: "Inspects goods before they ship. Bad stock comes back as refunds and a rating that suppresses every future sale.", comment: "Capability summary")
        case (.risk, .construction):
            return String(localized: "Funds specific mitigations and insurance cover against the incidents that can end a run.", comment: "Capability summary")
        case (.risk, .startup):
            return String(localized: "Funds specific safeguards and insurance against the incidents that can kill a company.", comment: "Capability summary")
        case (.risk, .importing):
            return String(localized: "Cover against customs holds, cargo loss, tariff changes and a buyer who does not pay.", comment: "Capability summary")
        case (.communications, .construction):
            return String(localized: "Builds client trust, which decides how fast you get paid and whether they grant an extension.", comment: "Capability summary")
        case (.communications, .startup):
            return String(localized: "Builds investor confidence, which decides how fast tranches wire and whether they extend the runway.", comment: "Capability summary")
        case (.communications, .importing):
            return String(localized: "Builds buyer relationships, which decide how fast you are paid and how much of the market you get.", comment: "Capability summary")
        case (.training, .construction):
            return String(localized: "Sends workers on courses. They earn nothing while away and come back permanently better.", comment: "Capability summary")
        case (.training, .startup):
            return String(localized: "Puts engineers on focused learning. They ship nothing while away and come back permanently better.", comment: "Capability summary")
        case (.training, .importing):
            return String(localized: "Puts the team on focused learning. They handle nothing while away and come back permanently better.", comment: "Capability summary")
        }
    }
}

// MARK: - Mitigation naming

extension MitigationClass {
    /// Five buckets of things that go wrong, shared by every scenario so
    /// that Risk stays one system. Only the labels change.
    func name(in scenario: ScenarioKind) -> String {
        switch (self, scenario) {
        case (.weather, .construction):   return String(localized: "Weather protection", comment: "Mitigation name")
        case (.weather, .startup):        return String(localized: "Infrastructure resilience", comment: "Mitigation name")
        case (.weather, .importing):      return String(localized: "Freight contingency", comment: "Mitigation name")
        case (.security, .construction):  return String(localized: "Site security", comment: "Mitigation name")
        case (.security, .startup):       return String(localized: "Security & compliance", comment: "Mitigation name")
        case (.security, .importing):     return String(localized: "Cargo insurance", comment: "Mitigation name")
        case (.safety, .construction):    return String(localized: "Safety programme", comment: "Mitigation name")
        case (.safety, .startup):         return String(localized: "Team health", comment: "Mitigation name")
        case (.safety, .importing):       return String(localized: "Team health", comment: "Mitigation name")
        case (.technical, .construction): return String(localized: "Technical review", comment: "Mitigation name")
        case (.technical, .startup):      return String(localized: "Code review & testing", comment: "Mitigation name")
        case (.technical, .importing):    return String(localized: "Pre-shipment inspection", comment: "Mitigation name")
        case (.client, .construction):    return String(localized: "Contract management", comment: "Mitigation name")
        case (.client, .startup):         return String(localized: "Investor management", comment: "Mitigation name")
        case (.client, .importing):       return String(localized: "Customs brokerage", comment: "Mitigation name")
        }
    }

    func blurb(in scenario: ScenarioKind) -> String {
        switch (self, scenario) {
        case (.weather, .construction):   return String(localized: "Storm shielding and drainage. Cuts weather losses.", comment: "Mitigation description")
        case (.weather, .startup):        return String(localized: "Redundancy and failover. Cuts losses when a provider goes down.", comment: "Mitigation description")
        case (.weather, .importing):      return String(localized: "Backup carriers and booked capacity. Cuts losses when freight seizes up.", comment: "Mitigation description")
        case (.security, .construction):  return String(localized: "Fencing, lighting, night watch. Stops material walking off site.", comment: "Mitigation description")
        case (.security, .startup):       return String(localized: "Audits, secrets hygiene, access control. Stops a breach becoming a disaster.", comment: "Mitigation description")
        case (.security, .importing):     return String(localized: "Covers goods in transit. Stops a lost container becoming a lost season.", comment: "Mitigation description")
        case (.safety, .construction):    return String(localized: "Toolbox talks and enforcement. Fewer incidents, fewer stoppages.", comment: "Mitigation description")
        case (.safety, .startup):         return String(localized: "Sane on-call and real time off. Fewer burnouts, fewer resignations.", comment: "Mitigation description")
        case (.safety, .importing):       return String(localized: "Sane hours and real time off. Fewer burnouts, fewer resignations.", comment: "Mitigation description")
        case (.technical, .construction): return String(localized: "Independent design checking. Catches clashes before they are built.", comment: "Mitigation description")
        case (.technical, .startup):      return String(localized: "Design docs and independent review. Catches bad decisions before they ship.", comment: "Mitigation description")
        case (.technical, .importing):    return String(localized: "Checks goods at the factory. Catches bad stock before you have paid to ship it.", comment: "Mitigation description")
        case (.client, .construction):    return String(localized: "Tight change control. Blunts scope creep and rejections.", comment: "Mitigation description")
        case (.client, .startup):         return String(localized: "Clear reporting and expectation setting. Blunts pivots and pushback.", comment: "Mitigation description")
        case (.client, .importing):       return String(localized: "A broker who knows the paperwork. Blunts holds and duty disputes.", comment: "Mitigation description")
        }
    }
}
