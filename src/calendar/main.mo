import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Char "mo:base/Char";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

actor {
  public type CalendarKind = { #individual; #group };

  public type Calendar = {
    id : Nat;
    kind : CalendarKind;
    name : Text;
    owner : Principal;
    members : [Principal];
    createdAt : Int;
    updatedAt : Int;
  };

  public type Event = {
    id : Nat;
    calendarId : Nat;
    title : Text;
    description : Text;
    startTime : Int;
    endTime : Int;
    createdBy : Principal;
    createdAt : Int;
    updatedAt : Int;
  };

  private let anonymousPrincipal : Principal = Principal.fromText("2vxsx-fae");

  stable var nextCalendarId : Nat = 1;
  stable var nextEventId : Nat = 1;
  stable var calendarEntries : [(Nat, Calendar)] = [];
  stable var eventEntries : [(Nat, Event)] = [];

  var calendars = HashMap.HashMap<Nat, Calendar>(32, Nat.equal, Nat.hash);
  var events = HashMap.HashMap<Nat, Event>(64, Nat.equal, Nat.hash);

  private func trim(value : Text) : Text {
    Text.trim(value, #predicate(Char.isWhitespace));
  };

  private func isAuthenticated(caller : Principal) : Bool {
    not Principal.equal(caller, anonymousPrincipal);
  };

  private func principalExists(items : [Principal], target : Principal) : Bool {
    for (item in items.vals()) {
      if (Principal.equal(item, target)) {
        return true;
      };
    };
    false;
  };

  private func normalizeMembers(owner : Principal, members : [Principal]) : [Principal] {
    let buffer = Buffer.Buffer<Principal>(members.size());
    for (member in members.vals()) {
      if (
        not Principal.equal(member, owner) and
        not Principal.equal(member, anonymousPrincipal) and
        not principalExists(Buffer.toArray(buffer), member)
      ) {
        buffer.add(member);
      };
    };
    Buffer.toArray(buffer);
  };

  private func isCalendarMember(caller : Principal, calendar : Calendar) : Bool {
    if (Principal.equal(caller, calendar.owner)) {
      return true;
    };

    principalExists(calendar.members, caller);
  };

  private func requireCalendarAccess(caller : Principal, calendar : Calendar) : Result.Result<(), Text> {
    if (isCalendarMember(caller, calendar)) {
      #ok(());
    } else {
      #err("no permission");
    };
  };

  private func validateName(name : Text, field : Text) : Result.Result<Text, Text> {
    let cleaned = trim(name);
    if (Text.size(cleaned) == 0) {
      #err(field # " cannot be empty");
    } else {
      #ok(cleaned);
    };
  };

  public shared ({ caller }) func createIndividualCalendar(name : Text) : async Result.Result<Calendar, Text> {
    if (not isAuthenticated(caller)) {
      return #err("anonymous caller is not allowed");
    };

    let validatedName = validateName(name, "calendar name");
    switch (validatedName) {
      case (#err(message)) { #err(message) };
      case (#ok(cleanedName)) {
        let now = Time.now();
        let calendar : Calendar = {
          id = nextCalendarId;
          kind = #individual;
          name = cleanedName;
          owner = caller;
          members = [];
          createdAt = now;
          updatedAt = now;
        };
        calendars.put(calendar.id, calendar);
        nextCalendarId += 1;
        #ok(calendar);
      };
    };
  };

  public shared ({ caller }) func createGroupCalendar(name : Text, members : [Principal]) : async Result.Result<Calendar, Text> {
    if (not isAuthenticated(caller)) {
      return #err("anonymous caller is not allowed");
    };

    let validatedName = validateName(name, "calendar name");
    switch (validatedName) {
      case (#err(message)) { #err(message) };
      case (#ok(cleanedName)) {
        let now = Time.now();
        let calendar : Calendar = {
          id = nextCalendarId;
          kind = #group;
          name = cleanedName;
          owner = caller;
          members = normalizeMembers(caller, members);
          createdAt = now;
          updatedAt = now;
        };
        calendars.put(calendar.id, calendar);
        nextCalendarId += 1;
        #ok(calendar);
      };
    };
  };

  public query ({ caller }) func getMyCalendars() : async [Calendar] {
    if (not isAuthenticated(caller)) {
      return [];
    };

    let result = Buffer.Buffer<Calendar>(0);
    for ((_, calendar) in calendars.entries()) {
      if (isCalendarMember(caller, calendar)) {
        result.add(calendar);
      };
    };

    Buffer.toArray(result);
  };

  public query ({ caller }) func getCalendar(calendarId : Nat) : async ?Calendar {
    switch (calendars.get(calendarId)) {
      case null { null };
      case (?calendar) {
        if (isCalendarMember(caller, calendar)) {
          ?calendar;
        } else {
          null;
        };
      };
    };
  };

  public shared ({ caller }) func changeCalendarName(calendarId : Nat, name : Text) : async Result.Result<Calendar, Text> {
    if (not isAuthenticated(caller)) {
      return #err("anonymous caller is not allowed");
    };

    let validatedName = validateName(name, "calendar name");
    switch (validatedName) {
      case (#err(message)) { #err(message) };
      case (#ok(cleanedName)) {
        switch (calendars.get(calendarId)) {
          case null { #err("calendar not found") };
          case (?calendar) {
            if (not Principal.equal(caller, calendar.owner)) {
              return #err("no permission");
            };

            let updated : Calendar = {
              id = calendar.id;
              kind = calendar.kind;
              name = cleanedName;
              owner = calendar.owner;
              members = calendar.members;
              createdAt = calendar.createdAt;
              updatedAt = Time.now();
            };
            calendars.put(calendarId, updated);
            #ok(updated);
          };
        };
      };
    };
  };

  public shared ({ caller }) func addGroupMember(calendarId : Nat, member : Principal) : async Result.Result<Calendar, Text> {
    if (not isAuthenticated(caller)) {
      return #err("anonymous caller is not allowed");
    };

    if (Principal.equal(member, anonymousPrincipal)) {
      return #err("anonymous principal cannot be added");
    };

    switch (calendars.get(calendarId)) {
      case null { #err("calendar not found") };
      case (?calendar) {
        if (not Principal.equal(caller, calendar.owner)) {
          return #err("no permission");
        };

        switch (calendar.kind) {
          case (#individual) { #err("individual calendar does not support members") };
          case (#group) {
            if (Principal.equal(member, calendar.owner) or principalExists(calendar.members, member)) {
              return #err("member already exists");
            };

            let nextMembers = Array.append<Principal>(calendar.members, [member]);
            let updated : Calendar = {
              id = calendar.id;
              kind = calendar.kind;
              name = calendar.name;
              owner = calendar.owner;
              members = nextMembers;
              createdAt = calendar.createdAt;
              updatedAt = Time.now();
            };
            calendars.put(calendarId, updated);
            #ok(updated);
          };
        };
      };
    };
  };

  public shared ({ caller }) func removeGroupMember(calendarId : Nat, member : Principal) : async Result.Result<Calendar, Text> {
    if (not isAuthenticated(caller)) {
      return #err("anonymous caller is not allowed");
    };

    switch (calendars.get(calendarId)) {
      case null { #err("calendar not found") };
      case (?calendar) {
        if (not Principal.equal(caller, calendar.owner)) {
          return #err("no permission");
        };

        switch (calendar.kind) {
          case (#individual) { #err("individual calendar does not support members") };
          case (#group) {
            if (not principalExists(calendar.members, member)) {
              return #err("member not found");
            };

            let nextMembers = Array.filter<Principal>(
              calendar.members,
              func(current : Principal) : Bool {
                not Principal.equal(current, member);
              },
            );

            let updated : Calendar = {
              id = calendar.id;
              kind = calendar.kind;
              name = calendar.name;
              owner = calendar.owner;
              members = nextMembers;
              createdAt = calendar.createdAt;
              updatedAt = Time.now();
            };
            calendars.put(calendarId, updated);
            #ok(updated);
          };
        };
      };
    };
  };

  public shared ({ caller }) func createEvent(
    calendarId : Nat,
    title : Text,
    description : Text,
    startTime : Int,
    endTime : Int,
  ) : async Result.Result<Event, Text> {
    if (not isAuthenticated(caller)) {
      return #err("anonymous caller is not allowed");
    };

    if (endTime < startTime) {
      return #err("end time must be on or after start time");
    };

    let validatedTitle = validateName(title, "event title");
    switch (validatedTitle) {
      case (#err(message)) { #err(message) };
      case (#ok(cleanedTitle)) {
        switch (calendars.get(calendarId)) {
          case null { #err("calendar not found") };
          case (?calendar) {
            switch (requireCalendarAccess(caller, calendar)) {
              case (#err(message)) { #err(message) };
              case (#ok(_)) {
                let now = Time.now();
                let event : Event = {
                  id = nextEventId;
                  calendarId = calendarId;
                  title = cleanedTitle;
                  description = trim(description);
                  startTime = startTime;
                  endTime = endTime;
                  createdBy = caller;
                  createdAt = now;
                  updatedAt = now;
                };
                events.put(event.id, event);
                nextEventId += 1;
                #ok(event);
              };
            };
          };
        };
      };
    };
  };

  public shared ({ caller }) func updateEvent(
    eventId : Nat,
    title : Text,
    description : Text,
    startTime : Int,
    endTime : Int,
  ) : async Result.Result<Event, Text> {
    if (not isAuthenticated(caller)) {
      return #err("anonymous caller is not allowed");
    };

    if (endTime < startTime) {
      return #err("end time must be on or after start time");
    };

    let validatedTitle = validateName(title, "event title");
    switch (validatedTitle) {
      case (#err(message)) { #err(message) };
      case (#ok(cleanedTitle)) {
        switch (events.get(eventId)) {
          case null { #err("event not found") };
          case (?existing) {
            switch (calendars.get(existing.calendarId)) {
              case null { #err("calendar not found") };
              case (?calendar) {
                switch (requireCalendarAccess(caller, calendar)) {
                  case (#err(message)) { #err(message) };
                  case (#ok(_)) {
                    let updated : Event = {
                      id = existing.id;
                      calendarId = existing.calendarId;
                      title = cleanedTitle;
                      description = trim(description);
                      startTime = startTime;
                      endTime = endTime;
                      createdBy = existing.createdBy;
                      createdAt = existing.createdAt;
                      updatedAt = Time.now();
                    };
                    events.put(eventId, updated);
                    #ok(updated);
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  public shared ({ caller }) func deleteEvent(eventId : Nat) : async Result.Result<Bool, Text> {
    if (not isAuthenticated(caller)) {
      return #err("anonymous caller is not allowed");
    };

    switch (events.get(eventId)) {
      case null { #err("event not found") };
      case (?event) {
        switch (calendars.get(event.calendarId)) {
          case null { #err("calendar not found") };
          case (?calendar) {
            switch (requireCalendarAccess(caller, calendar)) {
              case (#err(message)) { #err(message) };
              case (#ok(_)) {
                ignore events.remove(eventId);
                #ok(true);
              };
            };
          };
        };
      };
    };
  };

  public query ({ caller }) func getEvent(eventId : Nat) : async Result.Result<Event, Text> {
    switch (events.get(eventId)) {
      case null { #err("event not found") };
      case (?event) {
        switch (calendars.get(event.calendarId)) {
          case null { #err("calendar not found") };
          case (?calendar) {
            switch (requireCalendarAccess(caller, calendar)) {
              case (#err(message)) { #err(message) };
              case (#ok(_)) { #ok(event) };
            };
          };
        };
      };
    };
  };

  public query ({ caller }) func getCalendarEvents(calendarId : Nat) : async Result.Result<[Event], Text> {
    switch (calendars.get(calendarId)) {
      case null { #err("calendar not found") };
      case (?calendar) {
        switch (requireCalendarAccess(caller, calendar)) {
          case (#err(message)) { #err(message) };
          case (#ok(_)) {
            let result = Buffer.Buffer<Event>(0);
            for ((_, event) in events.entries()) {
              if (event.calendarId == calendarId) {
                result.add(event);
              };
            };
            #ok(Buffer.toArray(result));
          };
        };
      };
    };
  };

  system func preupgrade() {
    calendarEntries := Iter.toArray(calendars.entries());
    eventEntries := Iter.toArray(events.entries());
  };

  system func postupgrade() {
    let calendarCapacity = Nat.max(1, calendarEntries.size());
    let eventCapacity = Nat.max(1, eventEntries.size());

    calendars := HashMap.HashMap<Nat, Calendar>(calendarCapacity, Nat.equal, Nat.hash);
    events := HashMap.HashMap<Nat, Event>(eventCapacity, Nat.equal, Nat.hash);

    for ((id, calendar) in calendarEntries.vals()) {
      calendars.put(id, calendar);
    };

    for ((id, event) in eventEntries.vals()) {
      events.put(id, event);
    };

    calendarEntries := [];
    eventEntries := [];
  };
};
