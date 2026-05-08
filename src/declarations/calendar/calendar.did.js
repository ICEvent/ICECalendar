export const idlFactory = ({ IDL }) => {
  const CalendarKind = IDL.Variant({ 'individual' : IDL.Null, 'group' : IDL.Null });
  const Calendar = IDL.Record({
    'id' : IDL.Nat,
    'kind' : CalendarKind,
    'name' : IDL.Text,
    'owner' : IDL.Principal,
    'members' : IDL.Vec(IDL.Principal),
    'createdAt' : IDL.Int,
    'updatedAt' : IDL.Int,
  });
  const Event = IDL.Record({
    'id' : IDL.Nat,
    'calendarId' : IDL.Nat,
    'title' : IDL.Text,
    'description' : IDL.Text,
    'startTime' : IDL.Int,
    'endTime' : IDL.Int,
    'createdBy' : IDL.Principal,
    'createdAt' : IDL.Int,
    'updatedAt' : IDL.Int,
  });
  const ResultBool = IDL.Variant({ 'ok' : IDL.Bool, 'err' : IDL.Text });
  const ResultCalendar = IDL.Variant({ 'ok' : Calendar, 'err' : IDL.Text });
  const ResultEvent = IDL.Variant({ 'ok' : Event, 'err' : IDL.Text });
  const ResultEvents = IDL.Variant({ 'ok' : IDL.Vec(Event), 'err' : IDL.Text });

  return IDL.Service({
    'addGroupMember' : IDL.Func([IDL.Nat, IDL.Principal], [ResultCalendar], []),
    'changeCalendarName' : IDL.Func([IDL.Nat, IDL.Text], [ResultCalendar], []),
    'createEvent' : IDL.Func([IDL.Nat, IDL.Text, IDL.Text, IDL.Int, IDL.Int], [ResultEvent], []),
    'createGroupCalendar' : IDL.Func([IDL.Text, IDL.Vec(IDL.Principal)], [ResultCalendar], []),
    'createIndividualCalendar' : IDL.Func([IDL.Text], [ResultCalendar], []),
    'deleteEvent' : IDL.Func([IDL.Nat], [ResultBool], []),
    'getCalendar' : IDL.Func([IDL.Nat], [IDL.Opt(Calendar)], ['query']),
    'getCalendarEvents' : IDL.Func([IDL.Nat], [ResultEvents], ['query']),
    'getEvent' : IDL.Func([IDL.Nat], [ResultEvent], ['query']),
    'getMyCalendars' : IDL.Func([], [IDL.Vec(Calendar)], ['query']),
    'removeGroupMember' : IDL.Func([IDL.Nat, IDL.Principal], [ResultCalendar], []),
    'updateEvent' : IDL.Func([IDL.Nat, IDL.Text, IDL.Text, IDL.Int, IDL.Int], [ResultEvent], []),
  });
};

export const init = ({ IDL }) => { return []; };
