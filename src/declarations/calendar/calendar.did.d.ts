import type { Principal } from '@dfinity/principal';

export type CalendarKind = { 'individual' : null } | { 'group' : null };
export interface Calendar {
  'id' : bigint,
  'kind' : CalendarKind,
  'name' : string,
  'owner' : Principal,
  'members' : Array<Principal>,
  'createdAt' : bigint,
  'updatedAt' : bigint,
}
export interface Event {
  'id' : bigint,
  'calendarId' : bigint,
  'title' : string,
  'description' : string,
  'startTime' : bigint,
  'endTime' : bigint,
  'createdBy' : Principal,
  'createdAt' : bigint,
  'updatedAt' : bigint,
}
export type ResultBool = { 'ok' : boolean } | { 'err' : string };
export type ResultCalendar = { 'ok' : Calendar } | { 'err' : string };
export type ResultEvent = { 'ok' : Event } | { 'err' : string };
export type ResultEvents = { 'ok' : Array<Event> } | { 'err' : string };

export interface _SERVICE {
  'addGroupMember' : (arg_0: bigint, arg_1: Principal) => Promise<ResultCalendar>,
  'changeCalendarName' : (arg_0: bigint, arg_1: string) => Promise<ResultCalendar>,
  'createEvent' : (
      arg_0: bigint,
      arg_1: string,
      arg_2: string,
      arg_3: bigint,
      arg_4: bigint,
    ) => Promise<ResultEvent>,
  'createGroupCalendar' : (arg_0: string, arg_1: Array<Principal>) => Promise<ResultCalendar>,
  'createIndividualCalendar' : (arg_0: string) => Promise<ResultCalendar>,
  'deleteEvent' : (arg_0: bigint) => Promise<ResultBool>,
  'getCalendar' : (arg_0: bigint) => Promise<[] | [Calendar]>,
  'getCalendarEvents' : (arg_0: bigint) => Promise<ResultEvents>,
  'getEvent' : (arg_0: bigint) => Promise<ResultEvent>,
  'getMyCalendars' : () => Promise<Array<Calendar>>,
  'removeGroupMember' : (arg_0: bigint, arg_1: Principal) => Promise<ResultCalendar>,
  'updateEvent' : (
      arg_0: bigint,
      arg_1: string,
      arg_2: string,
      arg_3: bigint,
      arg_4: bigint,
    ) => Promise<ResultEvent>,
}
